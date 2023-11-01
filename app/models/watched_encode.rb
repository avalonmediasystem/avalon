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

class WatchedEncode < ActiveEncode::Base
  include ::ActiveEncode::Persistence
  include ::ActiveEncode::Polling

  around_create do |encode, block|
    master_file_id = encode.options[:master_file_id]
    encode = block.call
    master_file = MasterFile.find(master_file_id)
    master_file.workflow_id = encode.id
    master_file.encoder_classname = self.class.name
    master_file.save
  end

  after_completed do |encode|
    record = ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s)

    # Upload to S3 if using ffmpeg or passthrough adapter
    if Settings.encoding.derivative_bucket &&
       (Settings.encoding.engine_adapter.to_sym == :ffmpeg || is_a?(PassThroughEncode))
      bucket = Aws::S3::Bucket.new(name: Settings.encoding.derivative_bucket)
      encode.output.collect! do |output|
        file = FileLocator.new output.url
        key = file.location.sub(/\/(.*?)\//, "")
        obj = bucket.object key

        if File.exist? file.location
          obj.upload_file file.location
          File.delete file.location
        else
          # Calls to Addressable::URI.escape here are to counter the unescaping that happens in FileLocator
          # This is needed because files uploaded to minio (and probably AWS) escape spaces (%20) instead of keeping spaces
          obj.upload_file Addressable::URI.escape(file.location)
          File.delete Addressable::URI.escape(file.location)
        end

        output.url = "s3://#{obj.bucket.name}/#{obj.key}"
        output
      end

      # Save translated output urls
      record.update(raw_object: encode.to_json)
    end

    master_file = MasterFile.find(record.master_file_id)
    master_file.update_progress_on_success!(encode)
  end

  def persistence_model_attributes(encode, create_options = nil)
    display_title = parse_filename(encode.input.url)
    options_hash = { title: display_title, display_title: display_title }
    if create_options.present? && create_options[:master_file_id].present?
      master_file = MasterFile.find(create_options[:master_file_id])
      options_hash[:master_file_id] = create_options[:master_file_id]
      options_hash[:media_object_id] = master_file.media_object_id
    end
    super.merge(options_hash.select { |_, v| v.present? })
  end

  protected

    def localize_s3_file(url)
      FileLocator.new(url).local_location
    end

    def parse_filename(url)
      escaped_url = Addressable::URI.escape(url)
      uri = URI.parse(escaped_url)
      escaped_filename = uri.path.split('/').last
      Addressable::URI.unescape(escaped_filename)
    rescue URI::InvalidURIError
      url
    end
end
