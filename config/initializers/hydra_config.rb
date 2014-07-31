require 'hydra/head' unless defined? Hydra

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
  # config.permissions.discover.group       = ActiveFedora::SolrService.solr_name("discover_access_group", :symbol)
  # config.permissions.discover.individual  = ActiveFedora::SolrService.solr_name("discover_access_person", :symbol)
  # config.permissions.read.group           = ActiveFedora::SolrService.solr_name("read_access_group", :symbol)
  # config.permissions.read.individual      = ActiveFedora::SolrService.solr_name("read_access_person", :symbol)
  # config.permissions.edit.group           = ActiveFedora::SolrService.solr_name("edit_access_group", :symbol)
  # config.permissions.edit.individual      = ActiveFedora::SolrService.solr_name("edit_access_person", :symbol)
  #
  # config.permissions.embargo.release_date  = ActiveFedora::SolrService.solr_name("embargo_release_date", :stored_sortable, type: :date)
  # config.permissions.lease.expiration_date = ActiveFedora::SolrService.solr_name("lease_expiration_date", :stored_sortable, type: :date)
  #
  #
  # specify the user model
  # config.user_model = '#{model_name.classify}'
 
  config.permissions.inheritable.discover.group = ActiveFedora::SolrService.solr_name("inheritable_discover_access_group", :symbol)
  config.permissions.inheritable.discover.individual = ActiveFedora::SolrService.solr_name("inheritable_discover_access_person", :symbol)
  config.permissions.inheritable.read.group = ActiveFedora::SolrService.solr_name("inheritable_read_access_group", :symbol)
  config.permissions.inheritable.read.individual = ActiveFedora::SolrService.solr_name("inheritable_read_access_person", :symbol)
  config.permissions.inheritable.edit.group = ActiveFedora::SolrService.solr_name("inheritable_edit_access_group", :symbol)
  config.permissions.inheritable.edit.individual = ActiveFedora::SolrService.solr_name("inheritable_edit_access_person", :symbol)
  config.permissions.policy_class = Admin::Collection
 
end
