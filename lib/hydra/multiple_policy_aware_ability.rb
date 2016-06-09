# Repeats access controls evaluation methods, but checks against a governing "Policy" object (or "Collection" object) that provides inherited access controls.
module Hydra::MultiplePolicyAwareAbility
  extend ActiveSupport::Concern
  include Hydra::Ability
  
  # Extends Hydra::Ability.test_edit to try policy controls if object-level controls deny access
  def test_edit(pid)
    result = super
    if result 
      return result
    else
      return test_edit_from_policy(pid)
    end
  end
  
  # Extends Hydra::Ability.test_read to try policy controls if object-level controls deny access
  def test_read(pid)
    result = super
    if result 
      return result
    else
      return test_read_from_policy(pid)
    end
  end
  
  # Returns the pid of policy object (is_governed_by) for the specified object
  # Assumes that the policy object is associated by an is_governed_by relationship 
  # (which is stored as "is_governed_by_ssim" in object's solr document)
  # Returns nil if no policy associated with the object
  def policy_pids_for(object_pid)
    policy_pids = policy_pids_cache[object_pid]
    return policy_pids if policy_pids
    solr_result = ActiveFedora::Base.find_with_conditions({:id=>object_pid}, :fl=>ActiveFedora::SolrService.solr_name('is_governed_by', :symbol))
    begin
      policy_pids_cache[object_pid] = policy_pids = value_from_solr_field(solr_result, ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)).collect {|val| val.gsub("info:fedora/", "")}
    rescue NoMethodError
    end

    return policy_pids
  end

  def active_policy_pids_for(object_pid)
    policy_pids = policy_pids_for(object_pid)
    return nil if policy_pids.nil?

    ids = policy_classes.collect do |policy_class|
      id_clause = "(#{policy_pids.collect {|pid| escape_filter("id", pid)}.join(" OR ")})"
      policy_class_clause = policy_class_clause(policy_class)
      active_policy_pids = policy_class.find_with_conditions(id_clause + policy_class_clause, fl: "id", rows: policy_class.count )
      active_policy_pids.collect {|h| h.values }.flatten
    end
    ids.flatten
  end
  
  # Returns the permissions solr document for policy_pids
  # The document is stored in an instance variable, so calling this multiple times will only query solr once.
  # To force reload, set @policy_permissions_solr_cache to {} 
  def policy_permissions_doc(policy_pid)
    @policy_permissions_solr_cache ||= {}
    @policy_permissions_solr_cache[policy_pid] ||= get_permissions_solr_response_for_doc_id(policy_pid)
  end
  
  # Tests whether the object's governing policy object grants edit access for the current user
  def test_edit_from_policy(object_pid)
    policy_pids = active_policy_pids_for(object_pid)
    if policy_pids.nil?
      return false
    else
      Rails.logger.debug("[CANCAN] -policy- Do the POLICIES #{policy_pids} provide READ permissions for #{current_user.user_key}?")
      results = policy_pids.collect do |policy_pid|
        group_intersection = user_groups & edit_groups_from_policy( policy_pid )
        result = !group_intersection.empty? || edit_users_from_policy( policy_pid ).include?(current_user.user_key)
        result
      end
      result = results.any? {|result| !!result}
      Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
      return result
    end
  end   
  
  # Tests whether the object's governing policy object grants read access for the current user
  def test_read_from_policy(object_pid)
    policy_pids = active_policy_pids_for(object_pid)
    if policy_pids.nil?
      return false
    else
      Rails.logger.debug("[CANCAN] -policy- Do the POLICIES #{policy_pids} provide READ permissions for #{current_user.user_key}?")
      results = policy_pids.collect do |policy_pid|
        group_intersection = user_groups & read_groups_from_policy( policy_pid )
        result = !group_intersection.empty? || read_users_from_policy( policy_pid ).include?(current_user.user_key)
        result
      end
      result = results.any? {|result| !!result}
      Rails.logger.debug("[CANCAN] -policy- decision: #{result}")
      result
    end
  end 
  
  # Returns the list of groups granted edit access by the policy object identified by policy_pids
  def edit_groups_from_policy(policy_pids)
    policy_permissions = policy_permissions_doc(policy_pids)
    edit_group_field = Hydra.config[:permissions][:inheritable][:edit][:group]
    eg = ((policy_permissions == nil || policy_permissions.fetch(edit_group_field,nil) == nil) ? [] : policy_permissions.fetch(edit_group_field,nil))
    Rails.logger.debug("[CANCAN] -policy- edit_groups: #{eg.inspect}")
    return eg
  end

  # Returns the list of groups granted read access by the policy object identified by policy_pids
  # Note: edit implies read, so read_groups is the union of edit and read groups
  def read_groups_from_policy(policy_pids)
    policy_permissions = policy_permissions_doc(policy_pids)
    read_group_field = Hydra.config[:permissions][:inheritable][:read][:group]
    rg = edit_groups_from_policy(policy_pids) | ((policy_permissions == nil || policy_permissions.fetch(read_group_field,nil) == nil) ? [] : policy_permissions.fetch(read_group_field,nil))
    Rails.logger.debug("[CANCAN] -policy- read_groups: #{rg.inspect}")
    return rg
  end

  # Returns the list of users granted edit access by the policy object identified by policy_pids
  def edit_users_from_policy(policy_pids)
    policy_permissions = policy_permissions_doc(policy_pids)
    edit_user_field = Hydra.config[:permissions][:inheritable][:edit][:individual]
    eu = ((policy_permissions == nil || policy_permissions.fetch(edit_user_field,nil) == nil) ? [] : policy_permissions.fetch(edit_user_field,nil))
    Rails.logger.debug("[CANCAN] -policy- edit_users: #{eu.inspect}")
    return eu
  end

  # Returns the list of users granted read access by the policy object identified by policy_pids
  # Note: edit implies read, so read_users is the union of edit and read users
  def read_users_from_policy(policy_pids)
    policy_permissions = policy_permissions_doc(policy_pids)
    read_user_field = Hydra.config[:permissions][:inheritable][:read][:individual]
    ru = edit_users_from_policy(policy_pids) | ((policy_permissions == nil || policy_permissions.fetch(read_user_field, nil) == nil) ? [] : policy_permissions.fetch(read_user_field, nil))
    Rails.logger.debug("[CANCAN] -policy- read_users: #{ru.inspect}")
    return ru
  end
  
  private
  
  # Grabs the value of field_name from solr_result
  # @example
  #   solr_result = Multiresimage.find_with_conditions({:id=>object_pid}, :fl=>'is_governed_by_s')
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

  def policy_pids_cache
    @policy_pids_cache ||= {}
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
