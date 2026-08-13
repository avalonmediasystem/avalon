# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

class CollectionSearchBuilder < SearchBuilder
  self.default_processor_chain -= [:add_access_controls_to_solr_params, :term_frequency_counts, :search_section_transcripts]
  # self.default_processor_chain += [:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :gated_discovery_join]
  self.default_processor_chain += [:gated_discovery_join]
  # self.avalon_solr_access_filters_logic = [:only_published_items, :limit_to_non_hidden_items, :limit_to_inheritance_enabled_items]
  self.model = Admin::Collection

  attr_accessor :user

  # Override to allow searching on set user
  def add_access_controls_to_solr_params(solr_parameters)
    ability = Ability.new(user) if user.present?
    ability ||= current_ability

    return unless ability.cannot? :discover_everything, model

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_discovery_filters(discovery_permissions, ability).reject(&:blank?).join(' OR ')
    avalon_solr_access_filters_logic.each do |filter|
      solr_parameters[:fq] << send(filter, discovery_permissions, ability)
    end
    Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
  end

  def gated_discovery_join(solr_parameters)
    temp_solr_parameters = {}
    add_access_controls_to_solr_params(temp_solr_parameters)

    query =  "{!join from=isMemberOfCollection_ssim to=id}"
    subquery = temp_solr_parameters[:fq].present? ? "(#{temp_solr_parameters[:fq].join(') AND (')})" : "*:*"
    solr_parameters[:q] = query + subquery
    solr_parameters[:defType] = "lucene"
    solr_parameters[:rows] = 1_000_000
    Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
  end

  private

    def apply_gated_discovery(solr_parameters, permission_types = discovery_permissions, ability = current_ability)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << gated_discovery_filters(permission_types, ability).reject(&:blank?).join(' OR ')
    end
end
