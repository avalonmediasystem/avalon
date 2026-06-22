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

# Repeats access controls evaluation methods, but checks against a governing "Policy" object (or "Collection" object) that provides inherited access controls.
module Hydra::MultiplePolicyAwareAccessControlsEnforcement

  # Extends Hydra::AccessControlsEnforcement.apply_gated_discovery to reflect policy-provided access
  # appends the result of policy_clauses into the :fq
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def apply_gated_discovery(solr_parameters)
    super
    Rails.logger.debug("POLICY-aware Solr parameters: #{ solr_parameters.inspect }")
  end

  # returns solr query for finding all objects whose policies grant discover access to current_user
  def policy_clauses(permission_types: discovery_permissions)
    policy_ids = policies_with_access(permission_types: permission_types)
    return nil if policy_ids.empty?
    # find objects with policies connected to the object
    "_query_:\"{!terms f=isGovernedBy_ssim}#{policy_ids.join(',')}\""
  end

  # find all the policies that grant discover/read/edit permissions to this user or any of its groups
  def policies_with_access(permission_types: discovery_permissions)
    clauses = policy_classes.collect do |policy_class|
      user_access_filters = []
      # Grant access based on user id & group
      policy_class_clause = policy_class_clause(policy_class)
      user_access_filters += apply_policy_group_permissions(permission_types, policy_class_clause)
      user_access_filters += apply_policy_user_permissions(permission_types, policy_class_clause)
      "(has_model_ssim:\"#{policy_class.name}\" AND (#{user_access_filters.join(" OR ")}))"
    end
    Rails.logger.debug "get policies query: #{clauses.join(" OR ")}\n\n"
    result = ActiveFedora::Base.search_with_conditions( clauses.join(" OR "), :fl => "id", :rows => 100_000 )
    Rails.logger.debug "get policies: #{result}\n\n"
    ids = result.map {|h| h['id']}
    # Find collections governed by units returned in first query along with objects found in first query
    result = ActiveFedora::Base.search_with_conditions("_query_:\"{!terms f=id}#{ids.join(',')}\" OR _query_:\"{!terms f=isGovernedBy_ssim}#{ids.join(',')}\"", :fl => "id", :rows => 100_000 );
    Rails.logger.debug "get policies: #{result}\n\n"
    result.map {|h| h['id']}
  end

  def apply_policy_group_permissions(permission_types = discovery_permissions, policy_class_clause = "")
      # for groups
      user_access_filters = []
      permission_types.each do |type|
        user_access_filters << "(_query_:\"{!terms f=#{Hydra.config.permissions.inheritable[type.to_sym].group}}#{RSolr.solr_escape(current_ability.user_groups.join(','))}\"" + policy_class_clause + ")"
      end
      user_access_filters
  end

  def apply_policy_user_permissions(permission_types = discovery_permissions, policy_class_clause = "")
    # for individual user access
    user = current_ability.current_user
    return [] unless user && user.user_key.present?
    permission_types.map do |type|
      "(" + escape_filter(Hydra.config.permissions.inheritable[type.to_sym].individual, user.user_key) + policy_class_clause + ")"
    end
  end

  # Returns the Model used for AdminPolicy objects.
  # You can set this by overriding this method or setting Hydra.config[:permissions][:policy_class]
  # Defults to Hydra::AdminPolicy
  def policy_classes
    classes = Hydra.config.permissions.policy_class.keys if Hydra.config.permissions.policy_class.is_a? Hash
    classes ||= Array(Hydra.config.permissions.policy_class || Hydra::AdminPolicy)
    classes
  end

  def policy_class_clause(klass)
    clause = Hydra.config.permissions.policy_class[klass][:clause] if policy_classes.include?(klass)
    clause ||= ""
    clause
  end

  protected

  def gated_discovery_filters
    filters = super
    additional_clauses = policy_clauses
    unless additional_clauses.blank?
      filters << additional_clauses
    end
    filters
  end
end
