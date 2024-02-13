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

class SpeedyAF::Proxy::Admin::Collection < SpeedyAF::Base
  # Override to handle section_id specially
  def initialize(solr_document, instance_defaults = {})
    instance_defaults ||= {}
    @model = SpeedyAF::Base.model_for(solr_document)
    @attrs = self.class.defaults.merge(instance_defaults)
    solr_document.each_pair do |k, v|
      attr_name, value = parse_solr_field(k, v)
      @attrs[attr_name.to_sym] = value
    end
    # Handle this case here until a better fix can be found for multiple solr fields which don't have a model property
    @attrs[:read_users] = solr_document["read_access_person_ssim"] || []
    @attrs[:edit_users] = solr_document["edit_access_person_ssim"] || []
  end

  def to_model
    self
  end

  def persisted?
    id.present?
  end

  def model_name
    ActiveModel::Name.new(Admin::Collection)
  end

  def to_param
    id
  end

  def cdl_enabled?
    if cdl_enabled.nil?
      Settings.controlled_digital_lending.collections_enabled
    elsif cdl_enabled != Settings.controlled_digital_lending.collections_enabled
      cdl_enabled
    else
      Settings.controlled_digital_lending.collections_enabled
    end
  end
end
