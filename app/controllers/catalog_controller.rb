# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  
  include Blacklight::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Controller::ControllerBehavior

  # These before_filters apply the hydra access controls
  before_filter :enforce_access_controls
  # before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  
  # Catch exceptions when you try to reference an object that doesn't exist.
  # Attempt to resolve it to a close match if one exists and offer a link to
  # the show page for that item. Otherwise ... nothing!
  rescue_from ActiveFedora::ObjectNotFoundError do |exception|
    render '/errors/unknown_pid', status: 404 
  end

  # This applies appropriate access controls to all solr queries
  self.solr_search_params_logic += [:add_access_controls_to_solr_params]
  
  # This filters out objects that you want to exclude from search results, like FileAssets
  self.solr_search_params_logic += [:exclude_unwanted_models]
  self.solr_search_params_logic += [:only_wanted_models]
  self.solr_search_params_logic += [:only_published_items]
  self.solr_search_params_logic += [:limit_to_current_user]

  configure_blacklight do |config|
    config.default_solr_params = { 
      :qt => 'search',
      :rows => 10
    }

    # solr field configuration for search results/index views
    config.index.show_link = 'title_t'
    config.index.record_display_type = 'has_model_s'

    # solr field configuration for document/show views
    config.show.html_title = 'title_t'
    config.show.heading = 'title_t'
    config.show.display_type = 'has_model_s'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar
    config.add_facet_field 'format_facet', :label => 'Format', :limit => 5
    # Eventually these need to be merged into a single facet
    config.add_facet_field 'contributor_facet', :label => 'Contributor', :limit => 5
    config.add_facet_field 'publisher_facet', :label => 'Publisher', :limit => 5
    config.add_facet_field 'subject_facet', :label => 'Subjects', :limit => 5
    config.add_facet_field 'genre_facet', :label => 'Genres', :limit => 5
    config.add_facet_field 'language_facet', :label => 'Languages', :limit => 5
    config.add_facet_field 'location_facet', :label => 'Locations', :limit => 5
    config.add_facet_field 'time_period_facet', :label => 'Time Periods', :limit => 5

    #FIXME hide these facets if not an "archivist"
    config.add_facet_field 'workflow_status_facet', :label => 'Status', :limit => 5, :if_user_can => [:manage, MediaObject]
    config.add_facet_field 'workflow_published_facet', :label => 'Published', :limit => 5, :if_user_can => [:manage, MediaObject]

    config.add_facet_field 'collection_facet', :label => 'Collection', :limit => 5
    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config.add_index_field 'title_display', :label => 'Title' 
    config.add_index_field 'format_display', :label => 'Format' 
    config.add_index_field 'creator_display', :label => 'Creator' 
    config.add_index_field 'date_created_display', :label => 'Creation date' 
    config.add_index_field 'language_display', :label => 'Language'
    config.add_index_field 'abstract_display', label: 'Summary'
    
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'title_display', :label => 'Title' 
    config.add_show_field 'format_display', :label => 'Format' 
    config.add_show_field 'creator_display', :label => 'Creator' 
    config.add_show_field 'language_display', :label => 'Language'
    config.add_show_field 'date_created_display', label: 'Creation date'
    config.add_show_field 'abstract_display', label: 'Abstract'
    config.add_show_field 'location_display', label: 'Locations'
    config.add_show_field 'time_period_display', label: 'Time periods'
    config.add_show_field 'contributor_display', label: 'Contributors'
    config.add_show_field 'publisher_display', label: 'Publisher'
    config.add_show_field 'genre_display', label: 'Genre'
    config.add_show_field 'publication_location_display', label: 'Place of publication'
    config.add_show_field 'terms_display', label: 'Terms'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    config.add_search_field 'all_fields', :label => 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = { 
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end
    
    config.add_search_field('creator') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'creator' }
      field.solr_local_parameters = { 
        :qf => '$creator_qf',
        :pf => '$creator_pf'
      }
    end
    
    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as 
    # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = { 
        :qf => '$subject_qf',
        :pf => '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_sort asc, date_created_sort desc', :label => 'Relevance'
    config.add_sort_field 'date_created_sort desc, title_sort asc', :label => 'Year'
    config.add_sort_field 'creator_sort asc, title_sort asc', :label => 'Creator'
    config.add_sort_field 'title_sort asc, date_created_sort desc', :label => 'Title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def only_wanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'has_model_s:"info:fedora/afmodel:MediaObject"'
  end

  def only_published_items(solr_parameters, user_parameters)
    if cannot? :create, MediaObject
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << 'workflow_published_facet:"Published"'
    end
  end

  def limit_to_current_user(solr_parameters, user_parameters)
    if params[:v] == "mi"
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "dc_creator_t: #{user_key}"
    end
  end

  def index
    super
    viewstate = params[:v]
    params[:v] = "ri"
    @recent_items = []
    (response, @recent_items) = get_search_results(
      {:q => 'has_model_s:"info:fedora/afmodel:MediaObject"',
       :per_page => 5,
       :sort => 'timestamp desc',
       :qt => "standard",
       :fl => "id"})
    unless current_user.nil?
      params[:v] = "mi"
      @my_items = []
      (response, @my_items) = get_search_results(
        {:q => 'workflow_published_facet:"Published"',
         :per_page => 5,
         :sort => 'system_create_dt desc',
         :qt => "standard",
         :fl => "id"})
    end
    params[:v] = viewstate
  end

  def matterhorn_service_config
    respond_to do |format|
      format.any(:xml, :json) { render request.format.to_sym => Hydrant.matterhorn_config }
    end
  end

  def layout
    'hydrant'
  end

end 
