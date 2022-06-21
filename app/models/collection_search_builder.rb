# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

class CollectionSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Hydra::MultiplePolicyAwareAccessControlsEnforcement

  self.default_processor_chain -= [:add_access_controls_to_solr_params]
  # self.default_processor_chain += [:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :gated_discovery_join]
  self.default_processor_chain += [:gated_discovery_join, :only_wanted_models]

  attr_accessor :user

  def only_wanted_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_ssim:"Admin::Collection"'
  end

  def add_access_controls_to_solr_params_if_not_admin(solr_parameters)
    ability = Ability.new(user) if user.present?
    ability ||= current_ability
    only_published_items(solr_parameters, ability)
    limit_to_non_hidden_items(solr_parameters, ability)
    apply_gated_discovery(solr_parameters, discovery_permissions, ability) if ability.cannot? :discover_everything, Admin::Collection
  end

  def gated_discovery_join(solr_parameters)
    temp_solr_parameters = {}
    add_access_controls_to_solr_params_if_not_admin(temp_solr_parameters)

    query =  "{!join from=isMemberOfCollection_ssim to=id}"
    subquery = temp_solr_parameters[:fq].present? ? "(#{temp_solr_parameters[:fq].join(') AND (')})" : "*:*"
    solr_parameters[:q] = query + subquery
    solr_parameters[:defType] = "lucene"
    solr_parameters[:rows] = 1_000_000
    Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
  end

  private

    # Grant access based on user id & group
    # @return [Array{Array{String}}]
    def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
      filters = super()
      filters + solr_access_filters_logic.map { |method| send(method, permission_types, ability).reject(&:blank?) }.reject(&:empty?)
    end

    def apply_gated_discovery(solr_parameters, permission_types = discovery_permissions, ability = current_ability)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << gated_discovery_filters(permission_types, ability).reject(&:blank?).join(' OR ')
    end

    # Copied from SearchBuilder
    def only_published_items(solr_parameters, ability = current_ability)
      if ability.cannot? :create, MediaObject
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << 'workflow_published_sim:"Published"'
      end
    end

    # Copied from SearchBuilder
    def limit_to_non_hidden_items(solr_parameters, ability = current_ability)
      if ability.cannot? :discover_everything, MediaObject
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << [policy_clauses, "(*:* NOT hidden_bsi:true)"].compact.join(" OR ")
      end
    end
end
