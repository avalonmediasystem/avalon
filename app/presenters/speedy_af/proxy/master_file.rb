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

class SpeedyAF::Proxy::MasterFile < SpeedyAF::Base
  def display_title
    mf_title = if has_structuralMetadata?
                 structuralMetadata.section_title
               elsif title.present?
                 title
               # FIXME: The test for media_object.master_file_ids.size is expensive and takes ~0.25 seconds
               elsif file_location.present? && (media_object.master_file_ids.size > 1)
                 file_location.split("/").last
               end
    mf_title.blank? ? nil : mf_title
  end

  # @return [SupplementalFile]
  def supplemental_files
    return [] if supplemental_files_json.blank?
    JSON.parse(supplemental_files_json).collect { |file_gid| GlobalID::Locator.locate(file_gid) }
  end
end
