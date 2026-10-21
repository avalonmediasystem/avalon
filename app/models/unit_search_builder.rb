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

class UnitSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Hydra::MultiplePolicyAwareAccessControlsEnforcement

  PERMISSION_GROUPS = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]

  class_attribute :default_avalon_solr_access_filters_logic
  self.default_avalon_solr_access_filters_logic = [:only_published_items, :limit_to_non_hidden_items, :limit_to_inheritance_enabled_items]

  self.default_processor_chain -= [:add_access_controls_to_solr_params]
  # self.default_processor_chain += [:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :gated_discovery_join]
  self.default_processor_chain += [:gated_discovery_join, :only_wanted_models]

  attr_accessor :user
  attr_writer :avalon_solr_access_filters_logic

  def only_wanted_models(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_ssim:"Admin::Unit"'
  end

  def only_published_items(_permission_types = discovery_permissions, _ability = current_ability)
    [edit_policy_clauses, 'workflow_published_sim:"Published"'].compact.join(" OR ")
  end

  def limit_to_non_hidden_items(_permission_types = discovery_permissions, _ability = current_ability)
    media_object_hidden_clause = "(disable_inheritance_bsi:true AND NOT hidden_bsi:true)"
    inherited_hidden_clause = "*:* AND NOT disable_inheritance_bsi:true"
    inherited_hidden_clause += " AND NOT #{hidden_policy_clauses}" if hidden_policy_clauses.present?
    inherited_hidden_clause = "(#{inherited_hidden_clause})"

    [edit_policy_clauses, media_object_hidden_clause, inherited_hidden_clause].compact.join(" OR ")
  end

  def limit_to_inheritance_enabled_items(_permission_types = discovery_permissions, ability = current_ability)
    current_user = ability.current_user.username
    user_groups = ability.user_groups - PERMISSION_GROUPS
    user_visibility_groups = ability.user_groups & PERMISSION_GROUPS
    read_access_clauses = []
    read_access_clauses += ["read_access_person_ssim:\"#{RSolr.solr_escape(current_user)}\""] if current_user.present?
    read_access_clauses += ["_query_:\"{!terms f=read_access_group_ssim}#{RSolr.solr_escape(user_groups.join(','))}\""] if user_groups.present?
    [edit_policy_clauses, "(*:* AND NOT disable_inheritance_bsi:true AND (#{(Array(read_policy_clauses) + read_access_clauses).join(" OR ")}))", "(disable_inheritance_bsi:true AND (#{(read_access_clauses + ["read_access_group_ssim:(#{user_visibility_groups.join(" OR ")})"]).join(" OR ")}))"].compact.join(" OR ")
  end

  def add_access_controls_to_solr_params_if_not_admin(solr_parameters)
    ability = Ability.new(user) if user.present?
    ability ||= current_ability
    apply_gated_discovery(solr_parameters, discovery_permissions, ability) if ability.cannot? :discover_everything, Admin::Unit
  end

  def gated_discovery_join(solr_parameters)
    temp_solr_parameters = {}
    add_access_controls_to_solr_params_if_not_admin(temp_solr_parameters)

    query =  "{!graph to=unit_ssim from=name_ssi}"
    subquery = temp_solr_parameters[:fq].present? ? "(#{temp_solr_parameters[:fq].join(') AND (')})" : "*:*"
    solr_parameters[:q] = "#{query}(#{subquery})"
    solr_parameters[:defType] = "lucene"
    solr_parameters[:rows] = 1_000_000
    Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
  end

  def avalon_solr_access_filters_logic
    @avalon_solr_access_filters_logic ||= self.default_avalon_solr_access_filters_logic
  end

  private

  def edit_policy_clauses
    @edit_policy_clauses ||= policy_clauses(permission_types: [:edit])
  end

  def read_policy_clauses
    @read_policy_clauses ||= policy_clauses(permission_types: [:read])
  end

  def hidden_policy_clauses
    @hidden_policy_clauses ||= policy_clauses(permission_types: [:read], additional_clause: "default_hidden_bsi:true")
  end

  # Grant access based on user id & group
  # @return [Array{Array{String}}]
  def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
    filters = super()
    filters + solr_access_filters_logic.map { |method| send(method, permission_types, ability).reject(&:blank?) }.reject(&:empty?)
  end

  def apply_gated_discovery(solr_parameters, permission_types = discovery_permissions, ability = current_ability)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_discovery_filters(permission_types, ability).reject(&:blank?).join(' OR ')
    avalon_solr_access_filters_logic.each do |filter|
      solr_parameters[:fq] << send(filter, discovery_permissions, current_ability)
    end
  end
end
