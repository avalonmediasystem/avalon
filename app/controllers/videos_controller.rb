class VideosController < ApplicationController
   include Hydra::Controller::FileAssetsBehavior
    
   # Look into other options in the future. For now just make it work
   before_filter :initialize_workflow, only: [:edit, :update]   
   before_filter :enforce_access_controls

  def new
    @video = Video.new
    @video.DC.creator = user_key
    set_default_item_permissions
    @video.save(:validate=>false)

    redirect_to edit_video_path(@video, step: 'file_upload')
  end
  
  # TODO : Refactor this to reflect the new code base
  def create
    logger.debug "<< Making a new Video object with a PBCore datastream >>"

    @video = Video.new
    @video.DC.creator = user_key
    @video.descMetadata.title = params[:title]
    @video.descMetadata.creator = params[:creator]
    @video.descMetadata.created_on = params[:created_on]
    set_default_item_permissions
    @video.save
    
    redirect_to edit_video_path(id: params[:pid], step: 'file_upload')
  end

  def edit
    logger.info "<< Retrieving #{params[:id]} from Fedora >>"
    
    @video = Video.find(params[:id])
    @video_asset = load_videoasset
    
    logger.debug "<< Calling update method >>"
  end
  
  # TODO: Refactor this to reflect the new code model. This is not the ideal way to
  #       handle a multi-screen workflow I suspect
  def update
    logger.info "<< Updating the video object (including a PBCore datastream) >>"
    @video = Video.find(params[:id])
    
    case params[:step]
      # When adding resource description
      when 'basic_metadata' 
        logger.debug "<< Populating required metadata fields >>"
        @video.descMetadata.title = params[:video][:title]        
        @video.descMetadata.creator = params[:video][:creator]
        @video.descMetadata.created_on = params[:video][:created_on]
        @video.descMetadata.abstract = params[:video][:abstract]

        @video.save
        next_step = 'access_control'
                
        logger.debug "<< #{@video.errors} >>"
        logger.debug "<< #{@video.errors.size} problems found in the data >>"        
      # When on the access control page
      when 'access_control' 
        # TO DO: Implement me
        logger.debug "<< Access flag = #{params[:access]} >>"
	@video.access = params[:access]        
        @video.save             
        logger.debug "<< Groups : #{@video.read_groups} >>"
        next_step = 'preview'

      # When looking at the preview page redirect to show
      #
      when 'preview' 
        # Do nothing for now      
      else
        next_step = 'file_upload'
    end     
    unless @video.errors.empty?
      report_errors
    else
      redirect_to get_redirect_path(next_step)
    end
  end
  
  def show
    @video = Video.find(params[:id])
    @video_asset = load_videoasset
    unless @video_asset.nil? 
      @stream = @video_asset.stream
      logger.debug("Stream location >> #{@stream}")

      @mediapackage_id = @video_asset.mediapackage_id
	  @mime_type = @video_asset.streaming_mime_type
    end
  end

  def destroy
    @video = Video.find(params[:id]).delete
    flash[:notice] = "#{params[:id]} has been deleted from the system"
    redirect_to root_path
  end
  
  protected
  def set_default_item_permissions
    unless @video.rightsMetadata.nil?
      @video.edit_groups = ['archivist']
      @video.edit_users = [user_key]
    end
  end
  
  def load_videoasset
    unless @video.parts.nil? or @video.parts.empty?
      VideoAsset.find(@video.parts.first.pid)
    else
      nil
    end
  end
  
  def initialize_workflow
    step_one = WorkflowStep.new(1, 'Manage files',
      'Associated bitstreams', 'file_upload')

    step_two = WorkflowStep.new(2, 'Resource description',
      'Metadata about the item', 'basic_metadata')

    step_three = WorkflowStep.new(3, 'Access control',
      'Who can access the item', 'access_control')

    step_four = WorkflowStep.new(4, 'Preview and publish',
      'Release the item for use', 'preview')
      
    @workflow_steps ||= [step_one, step_two, step_three, step_four]
  end
  
  def report_errors
    logger.debug "<< Errors found -> #{@video.errors} >>"
    logger.debug "<< #{@video.errors.size} >>" 
    
    flash[:error] = "There are errors with your submission. Please correct them before continuing."
    step = params[:step] || @workflow_steps.step.first.template
    render :edit and return
  end
  
  def get_redirect_path(target)
    logger.info "<< #{@video.pid} has been updated in Fedora >>"
    unless @workflow_steps.last.template == params[:step]
      redirect_path = edit_video_path(@video, step: target)
    else
      flash[:notice] = "This resource is now available for use in the system"
      redirect_path = video_path(@video)
      return
    end
    redirect_path
  end
end
