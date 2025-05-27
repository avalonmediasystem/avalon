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

class IndexedFile < ActiveFedora::File
  include SpeedyAF::IndexedContent
  MAX_CONTENT_SIZE = 512000

  # Override
  def original_name
    super&.force_encoding("UTF-8")
  end

  # Override to add binary content handling
  def to_solr(solr_doc = {}, opts = {})
    return solr_doc unless opts[:external_index]
    solr_doc.tap do |doc|
      doc[:id] = id
      doc[:has_model_ssim] = self.class.name
      doc[:uri_ss] = uri.to_s
      doc[:mime_type_ss] = mime_type
      doc[:original_name_ss] = original_name
      doc[:size_is] = content.present? ? content.size : 0
      doc[:'empty?_bs'] = content.blank?
      if index_content?
        doc[:content_ss] = binary_content? ? Base64.encode64(content) : content
      end
    end
  end

  protected

  def index_content?
    has_content? && size < MAX_CONTENT_SIZE
  end

  def binary_content?
    has_content? && mime_type !~ /(^text\/)|([\/\+]xml$)/
  end
end
