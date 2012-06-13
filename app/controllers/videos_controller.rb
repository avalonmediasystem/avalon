class VideosController < ApplicationController
  include Hydra::FileAssets
  before_filter :load_fedora_document, :only=>[:show,:edit]

  def new
    @video = Video.new
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
