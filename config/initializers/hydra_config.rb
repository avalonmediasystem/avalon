# windows doesn't properly require hydra-head (from the gemfile), so we need to require it explicitly here:
require 'hydra/head' unless defined? Hydra
# require 'hydra/datastream/rights_metadata'
require 'hydra/multiple_policy_aware_access_controls_enforcement'
require 'hydra/multiple_policy_aware_ability'

# TODO: remove the next line after fix is made for this method in hydra-access-controls
Hydra::AdminPolicyBehavior.send :remove_method, :default_permissions=

Rails.application.config.to_prepare do
  Hydra.configure do |config|
    silence_warnings do
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC = 'public'.freeze
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED = 'restricted'.freeze
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE = 'private'.freeze
    end

    # This specifies the solr field names of permissions-related fields.
    # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
    # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
    #
    # config.permissions.discover.group       = ActiveFedora::SolrQueryBuilder.solr_name("discover_access_group", :symbol)
    # config.permissions.discover.individual  = ActiveFedora::SolrQueryBuilder.solr_name("discover_access_person", :symbol)
    # config.permissions.read.group           = ActiveFedora::SolrQueryBuilder.solr_name("read_access_group", :symbol)
    # config.permissions.read.individual      = ActiveFedora::SolrQueryBuilder.solr_name("read_access_person", :symbol)
    # config.permissions.edit.group           = ActiveFedora::SolrQueryBuilder.solr_name("edit_access_group", :symbol)
    # config.permissions.edit.individual      = ActiveFedora::SolrQueryBuilder.solr_name("edit_access_person", :symbol)
    #
    # config.permissions.embargo.release_date  = ActiveFedora::SolrQueryBuilder.solr_name("embargo_release_date", :stored_sortable, type: :date)
    # config.permissions.lease.expiration_date = ActiveFedora::SolrQueryBuilder.solr_name("lease_expiration_date", :stored_sortable, type: :date)
    #
    #
    # Specify the user model
    # config.user_model = 'User'
    config.permissions.policy_class = {Admin::Collection => {}, Lease => {clause: " AND begin_time_dtsi:[* TO NOW] AND end_time_dtsi:[NOW TO *]"}}
    # config.permissions.policy_class = { Admin::Collection => {} }
  end
end

module Hydra::RoleMapperBehavior::ClassMethods
  def map
    RoleMap.reset! if RoleMap.count == 0
    RoleMap.load
  end

  def update
    m = map
    yield m
    RoleMap.replace_with! m
  end

  def byname
    @byname = map.each_with_object(Hash.new{ |h,k| h[k] = [] }) do |(role, usernames), memo|
      Array(usernames).each { |x| memo[x] << role unless x.nil? }
    end
  end
end

# Clear the role map out of the Rails cache so it initializes from the DB
Rails.cache.delete("RoleMapHash")
