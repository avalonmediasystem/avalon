class MediaObjectsController < CatalogController
  include Hydrant::Workflow::WorkflowControllerBehavior
#  include Hydra::Controller::FileAssetsBehavior

  before_filter :enforce_access_controls
  before_filter :inject_workflow_steps, only: [:edit, :update]
   
  def new
    logger.debug "<< NEW >>"
    @mediaobject = MediaObject.new(avalon_uploader: user_key)
    set_default_item_permissions
    # Touch the workflow object to create it by setting the origin
    @mediaobject.workflow.origin = 'web'
    @mediaobject.save(:validate => false)

    redirect_to edit_media_object_path(@mediaobject, step: HYDRANT_STEPS.first.step)
  end

  def edit
    logger.debug "<< EDIT >>"
    logger.info "<< Retrieving #{params[:id]} from Fedora >>"
    
    @mediaobject = MediaObject.find(params[:id])
    @masterFiles = load_master_files

    @active_step = params[:step] || @mediaobject.workflow.last_completed_step.first
    logger.debug "<< active_step: #{@active_step} >>"
    prev_step = HYDRANT_STEPS.previous(@active_step)
    context = params.merge!({mediaobject: @mediaobject})
    context = HYDRANT_STEPS.get_step(@active_step).before_step context
    
    case @active_step 
      # When uploading files be sure to get a list of all master files as
      # well as the list of dropbox accessible files
      when 'file-upload'
        @dropbox_files = context[:dropbox_files]
      when 'preview'
        @currentStream = set_active_file(params[:content])
        if (not @masterFiles.blank? and @currentStream.blank?) then
          @currentStream = @masterFiles.first
          flash[:notice] = "The stream was not recognized. Defaulting to the first available stream for the resource"
        end
      end

    unless prev_step.nil? || @mediaobject.workflow.completed?(prev_step.step) 
      redirect_to edit_media_object_path(@mediaobject)
      return
    end
  end
  
  # TODO: Refactor this to reflect the new code model. This is not the ideal way to
  #       handle a multi-screen workflow 
  def update
    logger.debug "<< UPDATE >>"
    logger.info "<< Updating the media object (including a PBCore datastream) >>"
    @mediaobject = MediaObject.find(params[:id])
 
    @active_step = params[:step] || @mediaobject.workflow.last_completed_step.first
    logger.debug "<< active_step: #{@active_step} >>"
    context = params.merge!({mediaobject: @mediaobject, user: user_key})
    context = HYDRANT_STEPS.get_step(@active_step).execute context

    unless @mediaobject.errors.empty?
      report_errors
    else
      unless params[:donot_advance] == "true"
        @mediaobject.workflow.update_status(@active_step)
	@mediaobject.save(validate: false)

        if HYDRANT_STEPS.has_next?(@active_step)
          @active_step = HYDRANT_STEPS.next(@active_step).step
        elsif @mediaobject.workflow.published?
          @active_step = "published"
        end
      end
      logger.debug "<< ACTIVE STEP => #{@active_step} >>"
      logger.debug "<< INGEST STATUS => #{@mediaobject.workflow.inspect} >>"
      respond_to do |format|
        format.html { (@mediaobject.workflow.published? and @mediaobject.workflow.current?(@active_step)) ? redirect_to(media_object_path(@mediaobject)) : redirect_to(get_redirect_path(@active_step)) }
        format.json { render :json => nil }
      end
    end
  end
  
  def destroy
    @mediaobject = MediaObject.find(params[:id]).delete
    flash[:notice] = "#{params[:id]} has been deleted from the system"
    redirect_to root_path
  end
  
  protected
  def set_default_item_permissions
    unless @mediaobject.rightsMetadata.nil?
      @mediaobject.edit_groups = ['archivist']
      @mediaobject.edit_users = [user_key]
    end
  end
  
  def report_errors
    logger.debug "<< Errors found -> #{@mediaobject.errors} >>"
    logger.debug "<< #{@mediaobject.errors.size} >>" 
    
    flash[:error] = "There are errors with your submission. Please correct them before continuing."
    step = params[:step] || HYDRANT_STEPS.first.template
    render :edit and return
  end
  
  def get_redirect_path(target)
    unless HYDRANT_STEPS.last?(params[:step])
      redirect_path = edit_media_object_path(@mediaobject, step: target)
    else
      flash[:notice] = "This resource is now available for use in the system"
      redirect_path = media_object_path(@mediaobject)
    end

    logger.info "<HYDRANT> Redirect path set to #{redirect_path} for #{@mediaobject}"
    redirect_path
  end
  
end
