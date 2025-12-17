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

class Admin::DashboardController < ApplicationController
  before_action :load_and_authorize_collections, only: [:index]
  before_action :load_and_authorize_units, only: [:index]

  def load_and_authorize_collections
    authorize!(params[:action].to_sym, Admin::Collection)
    repository = CatalogController.new.blacklight_config.repository
    # Allow the number of collections to be greater than 100
    blacklight_config.max_per_page = 100_000
    builder = ::CollectionSearchBuilder.new([:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :add_paging_to_solr], self).rows(100_000)
    
    response = repository.search(builder)

    # Query solr for facet values for collection media object counts and pass into presenter to avoid making 2 solr queries per collection
    count_query = "has_model_ssim:MediaObject"
    count_response = ActiveFedora::SolrService.get(count_query, { rows: 0, facet: true, 'facet.field': "isMemberOfCollection_ssim", 'facet.limit': -1 })
    counts_array = count_response["facet_counts"]["facet_fields"]["isMemberOfCollection_ssim"] rescue []
    counts = counts_array.each_slice(2).to_h
    unpublished_query = count_query + " AND workflow_published_sim:Unpublished"
    unpublished_count_response = ActiveFedora::SolrService.get(unpublished_query, { rows: 0, facet: true, 'facet.field': "isMemberOfCollection_ssim", 'facet.limit': -1 })
    unpublished_counts_array = unpublished_count_response["facet_counts"]["facet_fields"]["isMemberOfCollection_ssim"] rescue []
    unpublished_counts = unpublished_counts_array.each_slice(2).to_h

    @collections = response.documents.collect do |doc| 
                     ::Admin::CollectionPresenter.new(doc, 
                                                      media_object_count: (counts[doc.id] || 0),
                                                      unpublished_media_object_count: (unpublished_counts[doc.id] || 0))
                   end.sort_by { |c| c.name.downcase }
  end

  def load_and_authorize_units
    authorize!(params[:action].to_sym, Admin::Unit)
    repository = CatalogController.new.blacklight_config.repository
    # Allow the number of units to be greater than 100
    blacklight_config.max_per_page = 100_000
    builder = ::UnitSearchBuilder.new([:add_access_controls_to_solr_params_if_not_admin, :only_wanted_models, :add_paging_to_solr], self).rows(100_000)
    
    response = repository.search(builder)

    # Query solr for facet values for unit media object counts and pass into presenter to avoid making 2 solr queries per unit
    count_query = 'has_model_ssim:"Admin::Collection"'
    count_response = ActiveFedora::SolrService.get(count_query, { rows: 0, facet: true, 'facet.field': "heldBy_ssim", 'facet.limit': -1 })
    counts_array = count_response["facet_counts"]["facet_fields"]["heldBy_ssim"] rescue []
    counts = counts_array.each_slice(2).to_h

    @units = response.documents.collect { |doc| ::Admin::UnitPresenter.new(doc, collection_count: counts[doc.id] || 0) }
    @units = @units.sort_by { |u| u.name.downcase }
  end

  def index
    respond_to do |format|
      format.html
      # TODO: Figure out a json response?
    end
  end
end
