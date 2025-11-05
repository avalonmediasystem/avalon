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

# Repeats access controls evaluation methods, but checks against a governing "Policy" object (or "Collection" object) that provides inherited access controls.
module Hydra::MultiplePolicyAwareAbility
  extend ActiveSupport::Concern
  include Hydra::PolicyAwareAbility

  # Returns the id of policy object (is_governed_by) for the specified object
  # Assumes that the policy object is associated by an is_governed_by relationship
  # (which is stored as "is_governed_by_ssim" in object's solr document)
  # Returns nil if no policy associated with the object
  def policy_ids_for(object_id)
    policy_ids = policy_id_cache[object_id]
    return policy_ids if policy_ids
    solr_results = ActiveFedora::SolrService.query("id:#{object_id} OR _query_:\"{!join to=id from=isGovernedBy_ssim}id:#{object_id}\"", fl: [governed_by_solr_field])
    return unless solr_results.any?(&:present?)
    policy_id_cache[object_id] = policy_ids = solr_results.collect {|solr_result| solr_result[governed_by_solr_field] }.flatten
  end

  def active_policy_ids_for(object_id)
    policy_ids = policy_ids_for(object_id)
    return nil if policy_ids.nil?

    ids = policy_classes.collect do |policy_class|
      id_clause = "(#{policy_ids.collect {|id| escape_filter("id", id)}.join(" OR ")})"
      policy_class_clause = policy_class_clause(policy_class)
      active_policy_ids = policy_class.search_with_conditions(id_clause + policy_class_clause, fl: "id", rows: policy_class.count )
      active_policy_ids.collect {|h| h.values }.flatten
    end
    ids.flatten
  end

  # Tests whether the object's governing policy object grants edit access for the current user
  def test_edit_from_policy(object_id)
    policy_ids = active_policy_ids_for(object_id)
    return false if policy_ids.nil?
    Rails.logger.debug("[CANCAN] -policy- Do the POLICIES #{policy_ids} provide READ permissions for #{current_user.user_key}?")
    results = policy_ids.collect do |policy_id|
      group_intersection = user_groups & edit_groups_from_policy( policy_id )
      result = !group_intersection.empty? || edit_users_from_policy( policy_id ).include?(current_user.user_key)
      result
    end
    result = results.any? {|result| !!result}
    Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
    result
  end

  # Tests whether the object's governing policy object grants read access for the current user
  def test_read_from_policy(object_id)
    policy_ids = active_policy_ids_for(object_id)
    return false if policy_ids.nil?
    Rails.logger.debug("[CANCAN] -policy- Do the POLICIES #{policy_ids} provide READ permissions for #{current_user.user_key}?")
    results = policy_ids.collect do |policy_id|
      group_intersection = user_groups & read_groups_from_policy( policy_id )
      result = !group_intersection.empty? || read_users_from_policy( policy_id ).include?(current_user.user_key)
      result
    end
    result = results.any? {|result| !!result}
    Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
    result
  end

  private

  # Grabs the value of field_name from solr_result
  # @example
  #   solr_result = Multiresimage.search_with_conditions({:id=>object_id}, :fl=>'is_governed_by_s')
  #   value_from_solr_field(solr_result, 'is_governed_by_s')
  #   => ["info:fedora/changeme:2278"]
  def value_from_solr_field(solr_result, field_name)
    field_from_result = solr_result.select {|x| x.has_key?(field_name)}.first
    if field_from_result.nil?
      return nil
    else
      return field_from_result[field_name]
    end
  end

  # Returns the Model used for AdminPolicy objects.
  # You can set this by overriding this method or setting Hydra.config[:permissions][:policy_class]
  # Defults to Hydra::AdminPolicy
  def policy_classes
    if Hydra.config[:permissions][:policy_class].nil?
      return [Hydra::AdminPolicy]
    elsif Hydra.config[:permissions][:policy_class].is_a? Hash
      return Hydra.config[:permissions][:policy_class].keys
    else
      return Hydra.config[:permissions][:policy_class]
    end
  end

  def policy_class_clause(klass)
    if Hydra.config[:permissions][:policy_class].nil? || Hydra.config[:permissions][:policy_class][klass].nil?
      ""
    else
      Hydra.config[:permissions][:policy_class][klass][:clause] || ""
    end
  end

  def escape_filter(key, value)
    [key, value.gsub(/[ :\/]/, ' ' => '\ ', '/' => '\/', ':' => '\:')].join(':')
  end

end
