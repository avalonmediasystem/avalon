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

module IiifSupplementalFileBehavior
  private

  def supplemental_files_rendering(object)
    tags = ['caption', 'description', nil]
    supplemental_files = []
    tags.each do |tag|
      supplemental_files += object.supplemental_files(tag: tag).collect do |sf|
                              {
                                "@id" => object_supplemental_file_url(object, sf),
                                "type" => determine_rendering_type(sf.file.content_type),
                                "label" => { "en" => [sf.label] },
                                "format" => sf.file.content_type
                              }
      end
    end

    supplemental_files
  end

  def object_supplemental_file_url(object, supplemental_file)
    if object.is_a?(MasterFile) || object.is_a?(SpeedyAF::Proxy::MasterFile)
      Rails.application.routes.url_helpers.master_file_supplemental_file_url(id: supplemental_file.id, master_file_id: object.id)
    else
      Rails.application.routes.url_helpers.media_object_supplemental_file_url(id: supplemental_file.id, media_object_id: object.id)
    end
  end

  def determine_rendering_type(mime)
    case mime
    when 'application/pdf', 'application/msword', 'application/vnd.oasis.opendocument.text', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/html', 'text/plain', 'text/srt', 'text/vtt'
      'Text'
    when /image\/.+/
      'Image'
    when /audio\/.+/
      'Audio'
    when /video\/.+/
      'Video'
    else
      'Dataset'
    end
  end
end
