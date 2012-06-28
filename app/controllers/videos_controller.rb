class VideosController < ApplicationController
  include Hydra::FileAssets
  
#  before_filter :load_fedora_document, :only=>[:show, :edit]
#  before_filter :load_document, :only=>[:show, :edit]
   
  # TO DO : Need to import solr logic at some point for indexing and configuration
  #         of facets

  def new
    @video = Video.new
    @video.DC.creator = user_key
    set_default_item_permissions
    @video.save

    redirect_to edit_video_path(@video, step: 'file_upload')
  end
  
  # TODO : Refactor this to reflect the new code base
  def create
    puts "<< Making a new Video object with a PBCore datastream >>"

    @video = Video.new
    @video.DC.creator = user_key
    @video.descMetadata.title = params[:title]
    @video.descMetadata.creator = params[:creator]
    @video.descMetadata.created_on = params[:created_on]
    set_item_permissions
    @video.save
    
    redirect_to edit_video_path(id: params[:pid], step: 'file_upload')
  end

  def edit
    puts "<< Retrieving #{params[:id]} from Fedora >>"
    @video = Video.find(params[:id])
    @video_asset = load_videoasset
    puts "<< Calling update method >>"
  end
  
  # TODO: Refactor this to reflect the new code model. This is not the ideal way to
  #       handle a multi-screen workflow I suspect
  def update
    puts "<< Updating the video object (including a PBCore datastream) >>"
    @video = Video.find(params[:id])
    
    case params[:step]
      when 'basic_metadata' then
        puts "<< Populating required metadata fields >>"
        @video.descMetadata.title = params[:metadata_title]
        @video.descMetadata.creator = params[:metadata_creator]
        @video.descMetadata.created_on = params[:metadata_createdon]
        @video.descMetadata.abstract = params[:metadata_abstract]

        puts "<< #{@video.descMetadata.to_xml} >>"
        @video.save
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
    @video_asset = load_videoasset
  end

  def destroy
    @video = Video.find(params[:id]).delete
    flash[:notice] = "#{params[:id]} has been withdrawn from the system"
    redirect_to :back 
  end
    
  protected
  def set_default_item_permissions
    unless @video.rightsMetadata.nil?
      permission = {
        "group" => { 
          "public" => "discover",
          "public" => "read", 
          "archivist" => "discover",
          "archivist" => "edit"},
        "person" => {"archivist1@example.com" => "edit"}}
      @video.rightsMetadata.update_permissions(permission)
    end
  end
  
  def load_videoasset
    unless @video.parts.nil? or @video.parts.empty?
      VideoAsset.find(@video.parts.first.pid)
    else
      nil
    end
  end
  
end
