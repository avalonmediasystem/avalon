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

class SpeedyAF::Proxy::MasterFile < SpeedyAF::Base
  def to_param
    id
  end

  def encoder_class
    find_encoder_class(encoder_classname) ||
      find_encoder_class("#{workflow_name}_encode".classify) ||
      find_encoder_class((Settings.encoding.engine_adapter + "_encode").classify) ||
      MasterFile.default_encoder_class ||
      WatchedEncode
  end

  def find_encoder_class(klass_name)
    klass = klass_name&.safe_constantize
    klass if klass&.ancestors&.include?(ActiveEncode::Base)
  end

  # We know that title will be indexed if present so return presence to avoid reifying
  def title
    attrs[:title].presence
  end

  def structure_title
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
  def supplemental_files(tag: '*')
    return [] if supplemental_files_json.blank?
    files = JSON.parse(supplemental_files_json).collect { |file_gid| GlobalID::Locator.locate(file_gid) }
    case tag
    when '*'
      files
    when nil
      files.select { |file| file.tags.empty? }
    else
      files.select { |file| Array(tag).all? { |t| file.tags.include?(t) } }
    end
  end

  def captions
    load_subresource_content(:captions) rescue nil
  end

  def permalink_with_query(query_vars = {})
    val = permalink
    if val && query_vars.present?
      val = "#{val}?#{query_vars.to_query}"
    end
    val ? val.to_s : nil
  end
end
