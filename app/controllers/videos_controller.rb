class VideosController < ApplicationController
  include Hydra::FileAssets

  def create
    puts "<< Making a new Video object with a PBCore datastream >>"
    @video = Video.new
    @video.descMetadata.title = params[:title]
    @video.descMetadata.creator = params[:creator]
    @video.descMetadata.created_on = params[:created_on]
    @video.save
    
    redirect_to hydra_asset_path(id: params[:pid])
  end

  def update
    puts "<< Updating the video object including a PBCore datastream >>"
    @video = Video.find(params[:pid])
    @video.descMetadata.title = params[:title]
    @video.descMetadata.creator = params[:creator]
    @video.descMetadata.created_on = params[:created_on]
    @video.save
    puts "<< #{@video.pid} has been updated in Fedora >>"

    redirect_to hydra_asset_path(id: params[:pid])
  end
end
