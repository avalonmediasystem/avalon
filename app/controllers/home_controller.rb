# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class HomeController < ApplicationController  

  include Blacklight::Catalog

  # These before_filters apply the hydra access controls
  before_filter :enforce_access_controls
  before_filter :enforce_viewing_context_for_show_requests, :only=>:show

  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.solr_search_params_logic << :exclude_unwanted_models

  def index
    @recent_items = []
    (response, document_list) = get_search_results(
      {:q => 'has_model_s:"info:fedora/afmodel:MediaObject"',
       :rows => 5, 
       :sort => 'timestamp desc', 
       :qt => "standard", 
       :fl => "id"})
    document_list.each { |doc|
      @recent_items << MediaObject.find(doc["id"])
    }
    @my_items = MediaObject.find({'dc_creator_t' => user_key}, {
      :sort => 'system_create_dt desc', 
      :rows => 5}) unless current_user.nil?
  end

end 
