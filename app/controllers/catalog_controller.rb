# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Hydra::Catalog
  include Hydra::MultiplePolicyAwareAccessControlsEnforcement
  include BlacklightHelperReloadFix

  # These before_actions apply the hydra access controls
  before_action :enforce_show_permissions, only: :show
  before_action :load_home_page_collections, only: :index, if: proc { helpers.current_page? root_path }

  configure_blacklight do |config|

    # Default component configuration
    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)
    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    config.http_method = :post

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      qt: 'search',
      rows: 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_tesi'
    config.index.display_type_field = 'has_model_ssim'
    config.index.thumbnail_method = :avalon_image_tag

    # solr field configuration for document/show views
    config.show.title_field = 'title_tesi'
    config.show.display_type_field = 'has_model_ssim'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _tsimed_ in a page.
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
    config.add_facet_field 'avalon_resource_type_ssim', label: 'Format', limit: 5, collapse: false, helper_method: :titleize
    config.add_facet_field 'creator_ssim', label: 'Main contributor', limit: 5
    config.add_facet_field 'date_sim', label: 'Date', limit: 5
    config.add_facet_field 'genre_ssim', label: 'Genres', limit: 5
    config.add_facet_field 'series_ssim', label: 'Series', limit: 5
    config.add_facet_field 'collection_ssim', label: 'Collection', limit: 5
    config.add_facet_field 'unit_ssim', label: 'Unit', limit: 5
    config.add_facet_field 'language_ssim', label: 'Language', limit: 5
    # Hide these facets if not a Collection Manager
    config.add_facet_field 'workflow_published_sim', label: 'Published', limit: 5, if: Proc.new {|context, config, opts| context.current_ability.can? :create, MediaObject}, group: "workflow"
    config.add_facet_field 'avalon_uploader_ssi', label: 'Created by', limit: 5, if: Proc.new {|context, config, opts| context.current_ability.can? :create, MediaObject}, group: "workflow"
    config.add_facet_field 'read_access_group_ssim', label: 'Item access', if: Proc.new {|context, config, opts| context.current_ability.can? :create, MediaObject}, group: "workflow", query: {
      public: { label: "Public", fq: "has_model_ssim:MediaObject AND read_access_group_ssim:#{Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC}" },
      restricted: { label: "Authenticated", fq: "has_model_ssim:MediaObject AND read_access_group_ssim:#{Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED}" },
      private: { label: "Private", fq: "has_model_ssim:MediaObject AND NOT read_access_group_ssim:#{Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC} AND NOT read_access_group_ssim:#{Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED}" }
    }
    config.add_facet_field 'read_access_virtual_group_ssim', label: 'External Group', limit: 5, if: Proc.new {|context, config, opts| context.current_ability.can? :create, MediaObject}, group: "workflow", helper_method: :vgroup_display
    config.add_facet_field 'date_digitized_ssim', label: 'Date Digitized', limit: 5, if: Proc.new {|context, config, opts| context.current_ability.can? :create, MediaObject}, group: "workflow"#, partial: 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'date_ingested_ssim', label: 'Date Ingested', limit: 5, if: Proc.new {|context, config, opts| context.current_ability.can? :create, MediaObject}, group: "workflow"
    config.add_facet_field 'has_captions_bsi', label: 'Has Captions', if: Proc.new {|context, config, opts| context.current_ability.can? :create, MediaObject}, group: "workflow", helper_method: :display_has_caption_or_transcript
    config.add_facet_field 'has_transcripts_bsi', label: 'Has Transcripts', if: Proc.new {|context, config, opts| context.current_ability.can? :create, MediaObject}, group: "workflow", helper_method: :display_has_caption_or_transcript

    config.add_facet_field 'subject_ssim', label: 'Subject', if: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'title_tesi', label: 'Title', if: Proc.new {|context, _field_config, _document| context.request.format == :json }
    config.add_index_field 'date_issued_ssi', label: 'Publication date'
    config.add_index_field 'date_created_ssi', label: 'Creation date'
    config.add_index_field 'creator_ssim', label: 'Main contributors', helper_method: :contributor_index_display
    config.add_index_field 'abstract_ssi', label: 'Summary', helper_method: :description_index_display
    config.add_index_field 'duration_ssi', label: 'Duration', if: Proc.new {|context, _field_config, _document| context.request.format == :json }
    config.add_index_field 'section_id_ssim', label: 'Sections', if: Proc.new {|context, _field_config, _document| context.request.format == :json }, helper_method: :section_id_json_index_display

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'title_tesi', label: 'Title'
    config.add_show_field 'resource_type_ssim', label: 'Format'
    config.add_show_field 'creator_ssim', label: 'Main Contributors'
    config.add_show_field 'language_ssim', label: 'Language'
    config.add_show_field 'date_issued_ssi', label: 'Date'
    config.add_show_field 'abstract_ssim', label: 'Abstract'
    config.add_show_field 'location_ssim', label: 'Locations'
    config.add_show_field 'contributor_ssim', label: 'Contributors'
    config.add_show_field 'publisher_ssim', label: 'Publisher'
    config.add_show_field 'genre_ssim', label: 'Genre'

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

    config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        qf: '$title_qf',
        pf: '$title_pf'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_local_parameters = {
        qf: '$author_qf',
        pf: '$author_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.qt = 'search'
      field.solr_local_parameters = {
        qf: '$subject_qf',
        pf: '$subject_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, title_ssort asc, date_issued_ssi desc', label: 'Relevance'
    config.add_sort_field 'date_issued_ssi desc, title_ssort asc', label: 'Date'
    config.add_sort_field 'creator_ssort asc, title_ssort asc', label: 'Main contributor'
    config.add_sort_field 'title_ssort asc, date_issued_ssi desc', label: 'Title'
    config.add_sort_field 'timestamp desc', label: 'Recently Updated', if: false

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    config.fetch_many_document_params = { fl: "*" }
  end

  private

    def load_home_page_collections
      featured_collections = Settings.home_page&.featured_collections
      if featured_collections.present?
        builder = ::CollectionSearchBuilder.new(self).rows(100_000)
        response = blacklight_config.repository.search(builder)
        collection = response.documents.select { |doc| featured_collections.include? doc.id }.sample
        @featured_collection = ::Admin::CollectionPresenter.new(collection) if collection
      end
    end
end
