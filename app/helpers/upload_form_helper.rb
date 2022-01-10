# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

module UploadFormHelper
  def direct_upload?
    Settings.encoding.engine_adapter.to_sym == :elastic_transcoder || Settings.minio.present?
  end

  def upload_form_classes
    result = %w(uploader-form form-horizontal step)
    result << 'directupload' if direct_upload?
    result.join(' ')
  end

  def upload_form_data
    if direct_upload?
      bucket = Aws::S3::Bucket.new(name: Settings.encoding.masterfile_bucket)
      direct_post = bucket.presigned_post(key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201')
      if Settings.minio.present? && Settings.minio.public_host.present?
        direct_post.url.sub!(Settings.minio.endpoint, Settings.minio.public_host)
      end
      {
        'form-data' => (direct_post.fields),
        'url' => direct_post.url,
        'host' => Addressable::URI.parse(direct_post.url).host
      }
    else
      {}
    end
  end
end
