# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

module MasterFileIntercom
  def to_ingest_api_hash(include_structure = true, remove_identifiers: false)
    {
      id: id,
      workflow_name: workflow_name,
      percent_complete: percent_complete,
      # percent_succeeded: percent_succeeded,
      # percent_failed: percent_failed,
      status_code: status_code,
      structure:  include_structure ? structuralMetadata.content : nil,
      label: title,
      thumbnail_offset: thumbnail_offset,
      poster_offset: poster_offset,
      physical_description: physical_description,
      file_location: file_location,
      file_size: file_size,
      duration: duration,
      date_digitized: date_digitized,
      file_checksum: file_checksum,
      file_format: file_format,
      other_identifier: (remove_identifiers ? [] : identifier.to_a),
      captions: captions&.content,
      # Captions (and all IndexedFile's) will return 'text/plain' when there isn't content including when it isn't persisted yet
      captions_type: captions.try(:persisted?) ? captions&.mime_type : nil,
      supplemental_file_captions: supplemental_file_captions,
      comment: comment.to_a,
      display_aspect_ratio: display_aspect_ratio,
      original_frame_size: original_frame_size,
      width: width,
      height: height,
      files: derivatives.collect(&:to_ingest_api_hash)
    }
  end
end
