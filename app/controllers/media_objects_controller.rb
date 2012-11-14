require 'hydrant/workflow/workflow_controller_behavior'
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
    @active_step = params[:step] || @mediaobject.workflow.last_completed_step
    prev_step = HYDRANT_STEPS.previous(@active_step)

    case @active_step 
      # When uploading files be sure to get a list of all master files as
      # well as the list of dropbox accessible files
      when 'file-upload'
        # This is a first cut at using an external workflow step. If it works
        # we can expand it in a more reasonable way
        #@dropbox_files = Hydrant::DropboxService.all
        context = {mediaobject: @mediaobject,
          parts: params[:parts]}
        fus = create_workflow_step('file_upload')
        context = fus.before_step context

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
    
    unless @mediaobject.workflow.completed?(@active_step)
      @ingest_status.current_step = @active_step
      @ingest_status.save
    end
  end
  
  # TODO: Refactor this to reflect the new code model. This is not the ideal way to
  #       handle a multi-screen workflow 
  def update
    logger.debug "<< UPDATE >>"
    logger.info "<< Updating the media object (including a PBCore datastream) >>"
    @mediaobject = MediaObject.find(params[:id])
 
    @active_step = params[:step] || @mediaobject.workflow.last_completed_step
    
    # This is a first pass towards abstracting the handling of workflow
    # processing into a processs that can be used either through the web
    # interface or through a batch process.
    #
    # Expect more changes as the right approach becomes obvious in future
    # sprints.
    case @active_step
      when 'file-upload'
        logger.debug "<< PROCESSING file-upload STEP >>"
        context = {mediaobject: @mediaobject,
          parts: params[:parts]}
        fus = create_workflow_step('file_upload')
        context = fus.execute context

      # When adding resource description
      when 'resource-description' 
        context = {mediaobject: @mediaobject,
          datastream: params[:media_object]}
        rds = create_workflow_step('resource-description')
        context = rds.execute context
      # When on the access control page
      when 'access-control' 
        context = {mediaobject: @mediaobject,
          access: params[:access]}
        acs = create_workflow_step('access-control')
        context = acs.execute context

      when 'structure'
        context = {mediaobject: @mediaobject,
          masterfiles: params[:masterfile_ids]}
        struct_step = create_workflow_step('structure')
        context = struct_step.execute context
       
      # When looking at the preview page use a version of the show page
      when 'preview' 
        # Publish the media object
        context = {mediaobject: @mediaobject,
          publisher: user_key}
        preview_step = create_workflow_step('preview')
        context = preview_step.execute context
    end    
    
    unless @mediaobject.errors.empty?
      report_errors
    else
      unless params[:donot_advance] == "true"
        @ingest_status = update_ingest_status(params[:pid], @active_step)
        if HYDRANT_STEPS.has_next?(@active_step)
          @active_step = HYDRANT_STEPS.next(@active_step).step
        elsif @ingest_status.published
          @active_step = "published"
        end
      end
      logger.debug "<< ACTIVE STEP => #{@active_step} >>"
      logger.debug "<< INGEST STATUS => #{@ingest_status.inspect} >>"
      respond_to do |format|
        format.html { (@ingest_status.published and @ingest_status.current?(@active_step)) ? redirect_to(media_object_path(@mediaobject)) : redirect_to(get_redirect_path(@active_step)) }
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
    logger.info "<< #{@mediaobject.pid} has been updated in Fedora >>"
    unless HYDRANT_STEPS.last?(params[:step])
      redirect_path = edit_media_object_path(@mediaobject, step: target)
    else
      flash[:notice] = "This resource is now available for use in the system"
      redirect_path = media_object_path(@mediaobject)
      return
    end
    redirect_path
  end
  
end
