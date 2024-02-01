# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

require 'addressable/uri'
require 'aws-sdk-s3'

class FileLocator
  attr_reader :source

  class S3File
    attr_reader :bucket, :key

    def initialize(uri)
      uri = Addressable::URI.parse(uri)
      @bucket = Addressable::URI.unencode(uri.host)
      @key = Addressable::URI.unencode(ActiveEncode.sanitize_uri(uri)).sub(%r(^/*(.+)/*$),'\1')
    end

    def object
      @object ||= Aws::S3::Object.new(bucket_name: bucket, key: key)
    end

    def local_file
      @local_file ||= Tempfile.new(File.basename(key))
      object.download_file(@local_file.path, mode: 'single_request') if File.zero?(@local_file)
      @local_file
    ensure
      @local_file.close
    end
  end

  def initialize(source)
    @source = source
  end

  def uri
    if @uri.nil?
      if source.is_a? File
        @uri = Addressable::URI.parse("file://#{Addressable::URI.escape(File.expand_path(source))}")
      else
        encoded_source = source
        begin
          @uri = Addressable::URI.parse(encoded_source)
        rescue Addressable::URI::InvalidURIError
          if encoded_source == source
            encoded_source = Addressable::URI.escape(encoded_source)
            retry
          else
            raise
          end
        end

        if @uri.scheme.nil?
          @uri = Addressable::URI.parse("file://#{Addressable::URI.escape(File.expand_path(source))}")
        end
      end
    end
    @uri
  end

  def location
    case uri.scheme
    when 's3'
      S3File.new(uri).object.presigned_url(:get)
    when 'file'
      # In case file name includes ? or # use full uri omitting components before path
      # instead of using only path which would miss query or fragment components
      Addressable::URI.unencode(uri.omit(:scheme, :user, :password, :host, :port))
    else
      @uri.to_s
    end
  end

  # If S3, download object to /tmp
  def local_location
    @local_location ||= begin
      if uri.scheme == 's3'
        S3File.new(uri).local_file.path
      else
        location
      end
    end
  end

  def exist?
    case uri.scheme
    when 's3'
      S3File.new(uri).object.exists?
    when 'file'
      File.exist?(location)
    else
      false
    end
  end
  alias_method :exists?, :exist?

  def reader
    case uri.scheme
    when 's3'
      S3File.new(uri).object.get.body
    when 'file'
      File.open(location,'r')
    else
      Kernel::open(uri.to_s, 'r')
    end
  end

  def attachment
    case uri.scheme
    when 's3'
      uri
    when 'file'
      File.open(location,'r')
    else
      location
    end
  end

  def self.remove_dir(path)
    if Settings.dropbox.path.match? %r{^s3://}
      remove_s3_dir(path)
    else
      remove_fs_dir(path)
    end
  end

  def self.remove_s3_dir(path)
    path_uri = Addressable::URI.parse(path)
    bucket = Aws::S3::Resource.new.bucket(Settings.encoding.masterfile_bucket)
    bucket.objects(prefix: "#{path_uri.path}/").batch_delete!

    # When directory is empty
    dropbox_dir = bucket.object("#{path_uri.path}/")
    dropbox_dir.delete if dropbox_dir.exists?
  end

  def self.remove_fs_dir(path)
    if File.directory?(path)
      FileUtils.remove_dir(path)
    else
      Rails.logger.error "Could not delete directory #{path}. Directory not found"
    end
  end
end
