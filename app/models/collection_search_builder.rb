# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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
# frozen_string_literal: true
class CollectionSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Hydra::MultiplePolicyAwareAccessControlsEnforcement

  self.default_processor_chain -= [:add_access_controls_to_solr_params]
  # self.default_processor_chain += [:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :gated_discovery_join]
  self.default_processor_chain += [:gated_discovery_join, :only_wanted_models]

  def only_wanted_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_ssim:"Admin::Collection"'
  end

  def add_access_controls_to_solr_params_if_not_admin(solr_parameters)
    add_access_controls_to_solr_params(solr_parameters) if current_ability.cannot? :discover_everything, Admin::Collection
  end

  def gated_discovery_join(solr_parameters)
    temp_solr_parameters = {}
    add_access_controls_to_solr_params_if_not_admin(temp_solr_parameters)
    query =  "{!join from=isMemberOfCollection_ssim to=id}*:*"
    query += " AND (#{temp_solr_parameters[:fq].first})" if temp_solr_parameters[:fq].present?
    solr_parameters[:q] = query
    solr_parameters[:defType] = "lucene"
  end
end
