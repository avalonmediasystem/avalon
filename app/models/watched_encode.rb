# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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
    # Upload to minio if using it with ffmpeg
    if Settings.minio && Settings.encoding.engine_adapter.to_sym == :ffmpeg
      bucket = Aws::S3::Bucket.new(name: Settings.encoding.derivative_bucket)
      encode.output.collect! do |output|
        file = FileLocator.new output.url
        key = file.location.sub(/\/(.*?)\//, "")
        obj = bucket.object key

        obj.upload_file file.location
        File.delete file.location

        output.url = "s3://#{obj.bucket.name}/#{obj.key}"
        output
      end
    end

    record = ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s)
    master_file = MasterFile.find(record.master_file_id)
    master_file.update_progress_on_success!(encode)
  end

  def persistence_model_attributes(encode, create_options = nil)
    display_title = encode.input.url.to_s.split('/').last
    options_hash = { display_title: display_title }
    if create_options.present? && create_options[:master_file_id].present?
      master_file = MasterFile.find(create_options[:master_file_id])
      options_hash[:master_file_id] = create_options[:master_file_id]
      options_hash[:media_object_id] = master_file.media_object_id
    end
    super.merge(options_hash.select { |_, v| v.present? })
  end

  protected

    def localize_s3_file(url)
      obj = FileLocator::S3File.new(url).object
      tempfile = Tempfile.new(File.basename(url))
      new_path = tempfile.path
      obj.download_file new_path

      new_path
    end
end
