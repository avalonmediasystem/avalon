# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---


module Avalon
  class Config
    def rehost(url, host=nil)
      if host.present?
        url.sub(%r{/localhost([/:])},"/#{host}\\1")
      else
        url
      end
    end

    def method_missing(sym, *args, &block)
      super(sym, *args, &block) unless @config.respond_to?(sym)
      @config.send(sym, *args, &block)
    end

    attr_writer :sanitize_filename
    def sanitize_filename
      @sanitize_filename ||= lambda do |filename|
        filename.gsub(/\s+/, '_')
      end
    end

    attr_writer :construct_download_path
    def construct_download_path
      @construct_download_path ||= lambda do |derivative|
        url = derivative.hls_url
        http_base = Settings.streaming.http_base

        # `Settings.streaming.server` returns symbols in testing environment
        # but strings in dev/prod. Explicitly call to_sym for consistency.
        location = case Settings.streaming.server.to_sym
                   # HLS Url templates can be found in config/url_handlers.yml
                   when :generic, :adobe
                     url.gsub(/(?:#{Regexp.escape(http_base)}\/)(?:audio-only\/)?(.*)(?:\.m3u8)/, '\1')
                   when :nginx
                     url.gsub(/(?:#{Regexp.escape(Settings.streaming.http_base)}\/)(.*)(?:\/index\.m3u8)/, '\1')
                   when :wowza
                     # Wowza HLS urls include the extension between the base and relative path.
                     # "http_base/extension:path/filename.extension/playlist.m3u8"
                     # (?:.*?:) is a non-capturing group that will non-greedily match
                     # any character until the first colon. This removes the extension from
                     # the middle of the path.
                     url.gsub(/(?:#{Regexp.escape(Settings.streaming.http_base)}\/)(?:.*?:)(.*)(?:\/playlist.m3u8)/, '\1')
                   end

        # Derivative files that have been moved from their original location/server should have been moved into
        # the new root path for derivatives/encodings. Combining the subpath from the existing record with the 
        # derivative path defined in our environment variables, we should be able to retrieve the derivative files, 
        # regardless of how many times they have been rehomed.
        if Settings.encoding.derivative_bucket
          File.join('s3://', Settings.encoding.derivative_bucket, location)
        else
          File.join(ENV["ENCODE_WORK_DIR"], location).to_s
        end
      end
    end

    attr_writer :construct_s3_download_object
    def construct_s3_download_object
      # Certain S3 implementations will require special handling to generate a usable download object.
      @construct_s3_download_object ||= lambda do |bucket, key, object|
        # Minio:
        # Because the request to the generated URL will be coming from an external context, we need
        # to generate the presigned URL with a publicly accessible endpoint. To accomplish this, we
        # create a new client definition using the public_host address and use that for access to the
        # object.
        if Settings.minio.present? && Settings.minio.public_host.present?
          client = Aws::S3::Client.new(endpoint: Settings.minio.public_host,
                                       access_key_id: Settings.minio.access,
                                       secret_access_key: Settings.minio.secret,
                                       region: ENV["AWS_REGION"])
          download_object = Aws::S3::Object.new(bucket_name: bucket, key: key, client: client)
        end
        # Most S3 implementations should be fine with the default client so we can simply
        # return the original object 
        download_object ||= object

        download_object
      end
    end

    # To be called as Avalon::Configuration.controlled_digital_lending_enabled?
    def controlled_digital_lending_enabled?
      !!Settings.controlled_digital_lending&.enable
    end

    private
    class << self
      def coerce(value, method)
        value.nil? ? nil : value.send(method)
      end

      def read_avalon_url(v)
        return({}) if v.nil?
        avalon_url = Addressable::URI.parse(v)
        { 'host'=>avalon_url.host, 'port'=>avalon_url.port, 'protocol'=>avalon_url.scheme }
      end

      def write_avalon_url(v)
        Addressable::URI.build(scheme: v.fetch('protocol','http'), host: v['host'], port: v['port']).to_s
      end
    end

    def deep_compact(value)
      if value.is_a?(Hash)
        new_value = value.dup
        new_value.each_pair { |k,v|
          compact_value = deep_compact(v)
          if compact_value.nil?
            new_value.delete(k)
          else
            new_value[k] = compact_value
          end
        }
        new_value.empty? ? nil : new_value
      else
        (value.nil? or (value.respond_to?(:empty?) and value.empty?)) ? nil : value
      end
    end
  end

  Configuration = Config.new
end
