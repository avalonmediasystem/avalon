class VideosController < ApplicationController
  include Hydra::FileAssets
  
  before_filter :load_fedora_document, :only=>[:show, :edit]
  before_filter :load_document

  # These before_filters apply the hydra access controls
  #before_filter :enforce_access_controls
  #before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  # This applies appropriate access controls to all solr queries
  #CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  #CatalogController.solr_search_params_logic << :exclude_unwanted_models


  def new
    @video = Video.new
    apply_depositor_metadata(@video)
    @video.save
    
    redirect_to edit_video_path(@video), step: 'file_upload'
  end
  
  # TODO : Refactor this to reflect the new code base
  def create
    puts "<< Making a new Video object with a PBCore datastream >>"

    @video = Video.new
    @video.descMetadata.title = params[:title]
    @video.descMetadata.creator = params[:creator]
    @video.descMetadata.created_on = params[:created_on]
    @video.save
    
    redirect_to hydra_asset_path(id: params[:pid])
  end

  def edit
    puts "<< Retrieving #{params[:id]} from Fedora >>"
    puts "<< File assets => #{@file_assets} >>"
    puts "<< Document => #{@document} >>"
    
    @video = Video.find(params[:id])
  end
  
  # TODO: Refactor this to reflect the new code model
  def update
    puts "<< Updating the video object including a PBCore datastream >>"
    @video = Video.find(params[:id])
    @video.descMetadata.title = params[:title]
    @video.descMetadata.creator = params[:creator]
    @video.descMetadata.created_on = params[:created_on]
    @video.save
    puts "<< #{@video.pid} has been updated in Fedora >>"

    redirect_to hydra_asset_path(id: params[:pid])
  end
end
