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

module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def current_sort_field
    actualSort = @response.sort if (@response and @response.sort.present?)
    actualSort ||= params[:sort]
    blacklight_config.sort_fields[actualSort] || default_sort_field
  end

  def display_found_in(document)
    metadata_count = document.to_h.sum {|k,v| k =~ /metadata_tf_/ ? v : 0 }
    transcript_count = document["sections"]["docs"].sum { |d| d["transcripts"]["docs"].sum {|s| s.sum {|k,v| k =~ /transcript_tf_/ ? v : 0 }}}
    section_count = document.to_h.sum {|k,v| k =~ /structure_tf_/ ? v : 0 }

    metadata = "metadata (#{metadata_count})" if metadata_count > 0
    transcript = "transcript (#{transcript_count})" if transcript_count > 0
    sections = "sections (#{section_count})" if section_count > 0

    [metadata, transcript, sections].compact.join(', ')
  end
end
