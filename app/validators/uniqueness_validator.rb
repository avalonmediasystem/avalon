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

class UniquenessValidator < ActiveModel::EachValidator
  def initialize(options)
    unless options[:solr_name].present?
      raise ArgumentError, "UniquenessValidator was not passed :solr_name. Example: validates :uniqueness => { :solr_name => 'name_tesim' }"
    end
    @solr_field = options[:solr_name]
    super
  end
  def validate_each(record, attribute, value)
    klass = record.class
    solr_value = record.to_solr[@solr_field]
    query = "has_model_ssim:\"#{klass.name}\""
    query += " AND #{@solr_field}:#{solr_value}" if solr_value.present? 
    existing_doc_id = ActiveFedora::SolrService.query(query, fl: [:id], rows: 1).first&.dig('id')
    if existing_doc_id.present? && existing_doc_id != record.id
      record.errors.add(attribute, :taken, value: value)
    end
  end
end
