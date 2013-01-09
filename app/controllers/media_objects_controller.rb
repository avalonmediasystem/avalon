require 'hydrant/controller/controller_behavior'

class MediaObjectsController < CatalogController
  include Hydrant::Workflow::WorkflowControllerBehavior
  include Hydrant::Controller::ControllerBehavior

  before_filter :enforce_access_controls
  before_filter :inject_workflow_steps, only: [:edit, :update]
   
  def new
    logger.debug "<< NEW >>"
    @mediaobject = MediaObjectsController.initialize_media_object(user_key)
    @mediaobject.workflow.origin = 'web'
    @mediaobject.save(:validate => false)

    redirect_to edit_media_object_path(@mediaobject)
  end

  def custom_edit
    if ['preview', 'structure', 'file-upload'].include? @active_step
      @masterFiles = load_master_files
    end

    if 'preview' == @active_step 
      @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first
      @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.mediapackage_id)
      @currentStreamInfo = @currentStream.derivatives.first.stream_details(@token) rescue {}

      if (not @masterFiles.empty? and @currentStream.blank?)
        @currentStream = @masterFiles.first
        flash[:notice] = "That stream was not recognized. Defaulting to the first available stream for the resource"
      end
    end
  end

  def show
    @mediaobject = MediaObject.find(params[:id])

    @masterFiles = load_master_files
    @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first
    @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.mediapackage_id)
    @currentStreamInfo = @currentStream.stream_details(@token) rescue {}

    respond_to do |format|
      # The flash notice is only set if you are returning HTML since it makes no
      # sense in an AJAX context (yet)
      format.html do
       	if (not @masterFiles.empty? and @currentStream.blank?)
          @currentStream = @masterFiles.first
          flash[:notice] = "That stream was not recognized. Defaulting to the first available stream for the resource"
        end
        render
      end
      format.json do
        render :json => @currentStreamInfo 
      end
    end
  end
  
  def destroy
    @mediaobject = MediaObject.find(params[:id]).delete
    flash[:notice] = "#{params[:id]} has been deleted from the system"
    redirect_to root_path
  end
 
  def mobile
    @mediaobject = MediaObject.find(params[:id])
    @masterFiles = @mediaobject.parts
    @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first

    render 'mobile', layout: false
  end

  def self.initialize_media_object( user_key )
    mediaobject = MediaObject.new( avalon_uploader: user_key )
    set_default_item_permissions( mediaobject, user_key )

    mediaobject
  end

  protected

  def load_master_files
    logger.debug "<< LOAD MASTER FILES >>"
    logger.debug "<< #{@mediaobject.parts} >>"

    @mediaobject.parts
  end

  # The goal of this method is to determine which stream to provide to the interface
  # for immediate playback. Eventually this might be replaced by an AJAX call but for
  # now to update the stream you must do a full page refresh.
  # 
  # If the stream is not a member of that media object or does not exist at all then
  # return a nil value that needs to be handled appropriately by the calling code
  # block
  def set_active_file(file_pid = nil)
    unless (@mediaobject.parts.blank? or file_pid.blank?)
      @mediaobject.parts.each do |part|
        return part if part.pid == file_pid
      end
    end

    # If you haven't dropped out by this point return an empty item
    nil
  end  
end
