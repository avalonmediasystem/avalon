class MediaObjectsController < ApplicationController
   include Hydra::Controller::FileAssetsBehavior
    
   # Look into other options in the future. For now just make it work
   before_filter :initialize_workflow, only: [:edit, :update]   
   before_filter :enforce_access_controls

  def new
    logger.debug "<< BEFORE : #{MediaObject.count} >>"
    
    @mediaobject = MediaObject.new
    @mediaobject.uploader = user_key
    set_default_item_permissions
    @mediaobject.save(:validate => false)

    logger.debug "<< AFTER : #{MediaObject.count} >>"
    redirect_to edit_media_object_path(@mediaobject, step: 'file_upload')
    logger.debug "<< Redirecting to edit view >>"
  end
  
  # TODO : Refactor this to reflect the new code base
  def create
    logger.debug "<< Making a new MediaObject object with a PBCore datastream >>"

    @mediaobject = MediaObject.new
    @mediaobject.uploader = user_key
    @mediaobject.title = params[:title]
    @mediaobject.creator = params[:creator]
    @mediaobject.created_on = params[:created_on]
    set_default_item_permissions
    @mediaobject.save
    
    redirect_to edit_media_object_path(id: params[:pid], step: 'file_upload')
  end

  def edit
    logger.info "<< Retrieving #{params[:id]} from Fedora >>"
    
    @mediaobject = MediaObject.find(params[:id])
    @masterfiles = load_master_files
    
    logger.debug "<< Calling update method >>"
  end
  
  # TODO: Refactor this to reflect the new code model. This is not the ideal way to
  #       handle a multi-screen workflow I suspect
  def update
    logger.info "<< Updating the media object object (including a PBCore datastream) >>"
    @mediaobject = MediaObject.find(params[:id])
    
    case params[:step]
      # When adding resource description
      when 'basic_metadata' 
        logger.debug "<< Populating required metadata fields >>"
        @mediaobject.title = params[:media_object][:title]        
        @mediaobject.creator = params[:media_object][:creator]
        @mediaobject.created_on = params[:media_object][:created_on]
        @mediaobject.abstract = params[:media_object][:abstract]

        @mediaobject.save
        next_step = 'access_control'
                
        logger.debug "<< #{@mediaobject.errors} >>"
        logger.debug "<< #{@mediaobject.errors.size} problems found in the data >>"        
      # When on the access control page
      when 'access_control' 
        # TO DO: Implement me
        logger.debug "<< Access flag = #{params[:access]} >>"
	    @mediaobject.access = params[:access]        
        @mediaobject.save             
        logger.debug "<< Groups : #{@mediaobject.read_groups} >>"
        next_step = 'preview'

      # When looking at the preview page redirect to show
      #
      when 'preview' 
        # Do nothing for now      
      else
        next_step = 'file_upload'
    end     
    unless @mediaobject.errors.empty?
      report_errors
    else
      redirect_to get_redirect_path(next_step)
    end
  end
  
  def show
    @mediaobject = MediaObject.find(params[:id])
    @masterfiles = load_master_files
    unless @masterfile.nil? 
      @stream = @masterfile.url
      logger.debug("Stream location >> #{@stream}")

      @mediapackage_id = @masterfile.mediapackage_id
      #@mime_type = @masterfile.streaming_mime_type
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
  
  def load_master_files
    unless @mediaobject.parts.nil? or @mediaobject.parts.empty?
      master_files = []
      @mediaobject.parts.each { |part| master_files << MasterFile.find(part.pid) }
      master_files
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
    logger.debug "<< Errors found -> #{@mediaobject.errors} >>"
    logger.debug "<< #{@mediaobject.errors.size} >>" 
    
    flash[:error] = "There are errors with your submission. Please correct them before continuing."
    step = params[:step] || @workflow_steps.step.first.template
    render :edit and return
  end
  
  def get_redirect_path(target)
    logger.info "<< #{@mediaobject.pid} has been updated in Fedora >>"
    unless @workflow_steps.last.template == params[:step]
      redirect_path = edit_media_object_path(@mediaobject, step: target)
    else
      flash[:notice] = "This resource is now available for use in the system"
      redirect_path = media_object_path(@mediaobject)
      return
    end
    redirect_path
  end
end
