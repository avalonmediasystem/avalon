class VideosController < ApplicationController
  include Hydra::FileAssets
  
  before_filter :load_fedora_document, :only=>[:show, :edit]
  before_filter :load_document

  # TO DO : Need to import solr logic at some point for indexing and configuration
  #         of facets

  def new
    @video = Video.new
    puts "<< 1 >>"
    apply_depositor_metadata(@video)
    puts "<< 2 >>"
    @video.save
    puts "<< 3 >>"

    redirect_to edit_video_path(@video, step: 'file_upload')
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
    @video = Video.find(params[:id])
  end
  
  # TODO: Refactor this to reflect the new code model. This is not the ideal way to
  #       handle a multi-screen workflow I suspect
  def update
    puts "<< Updating the video object including a PBCore datastream >>"
    @video = Video.find(params[:id])
    
    case params[:step]
      when 'basic_metadata' then
        puts "<< Populuting required metadata fields >>"
        @video.descMetadata.title = params[:title]
        @video.descMetadata.creator = params[:creator]
        @video.descMetadata.created_on = params[:created_on]
        @video.save
        puts "<< #{@video.descMetadata.to_xml} >>"
        next_step = 'preview'
      else
        next_step = 'file_upload'
    end
    puts "<< #{@video.pid} has been updated in Fedora >>"
    
    # Quick, dirty, and elegant solution to how to post back to the previous
    # screen
    unless 'preview' == next_step
      puts "<< Redirecting to the preview screen >>"
      redirect_to edit_video_path(@video, step: next_step)
    else
      redirect_to video_path(@video)
    end
  end
  
  def show
    @video = Video.find(params[:id])
  end

  def destroy
    @video = Video.find(params[:id]).delete
    flash[:notice] = "#{params[:id]} has been withdrawn from the system"
    redirect_to root_path 
  end
end
