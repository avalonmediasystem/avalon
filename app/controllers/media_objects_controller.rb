class MediaObjectsController < ApplicationController
   include Hydra::Controller::FileAssetsBehavior
       
   before_filter :enforce_access_controls
   before_filter :inject_workflow_steps, only: [:edit, :update]

  def new
    logger.debug "<< NEW >>"
    @mediaobject = MediaObject.new
    @mediaobject.uploader = user_key
    set_default_item_permissions
    @mediaobject.save(:validate => false)

    logger.debug "<< Creating a new Ingest Status >>"
    logger.debug "<< #{@mediaobject.inspect} >>"
    @ingest_status = IngestStatus.create(pid: @mediaobject.pid, 
      current_step: HYDRANT_STEPS.first.step)
    logger.debug "<< There are now #{IngestStatus.count} status in the database >>"
    
    redirect_to edit_media_object_path(@mediaobject, step: HYDRANT_STEPS.first.step)
  end
  
  def edit
    logger.debug "<< EDIT >>"
    logger.info "<< Retrieving #{params[:id]} from Fedora >>"
    
    @mediaobject = MediaObject.find(params[:id])
    @masterfiles = load_master_files
    @masterfiles_with_order = @mediaobject.parts_with_order
    if !@masterfiles.nil? && @masterfiles.count > 1 
      @relType = @mediaobject.descMetadata.relation_type[0]
    end

    @ingest_status = IngestStatus.find_by_pid(@mediaobject.pid)
    @active_step = params[:step] || @ingest_status.current_step
    prev_step = HYDRANT_STEPS.previous(@active_step)
    
    
    unless prev_step.nil? || @ingest_status.completed?(prev_step.step) 
      redirect_to edit_media_object_path(@mediaobject)
      return
    end
    
    unless @ingest_status.completed?(@active_step)
      @ingest_status.current_step = @active_step
      @ingest_status.save
    end
    
    logger.debug "<< INGEST STATUS => #{@ingest_status.inspect} >>"
    logger.debug "<< ACTIVE STEP => #{@active_step} >>"
    logger.debug "<< There are now #{IngestStatus.count} status in the database >>"
  end
  
  # TODO: Refactor this to reflect the new code model. This is not the ideal way to
  #       handle a multi-screen workflow 
  def update
    logger.debug "<< UPDATE >>"
    logger.info "<< Updating the media object (including a PBCore datastream) >>"
    @mediaobject = MediaObject.find(params[:id])
 
    @ingest_status = IngestStatus.find_by_pid(params[:id])
    @active_step = params[:step] || @ingest_status.current_step
    
    logger.info "<< #{@mediaobject.pid} - #{@active_step} >>"
    logger.debug "<< STEP PARAMETER => #{params[:step]} >>"
    logger.debug "<< ACTIVE STEP => #{@active_step} >>"
    
    case @active_step
      when 'file-upload'
        
      # When adding resource description
      when 'resource-description' 
        logger.debug "<< Populating required metadata fields >>"
        # Quick, dirty, and hacky but it works right?
        params[:media_object].each do |key, value|
          @mediaobject.update_attributes({key.to_s => value},
            datastream: :descMetadata) unless 'pid' == key
          logger.debug "<< Updating #{key} => #{value} >>"
          logger.debug "<< #{@mediaobject.descMetadata.to_xml} >>"
        end
        # End ugly hack   
        @mediaobject.save

        logger.debug "<< #{@mediaobject.errors} >>"
        logger.debug "<< #{@mediaobject.errors.size} problems found in the data >>"        
      # When on the access control page
      when 'access-control' 
        # TO DO: Implement me
        logger.debug "<< Access flag = #{params[:access]} >>"
	      @mediaobject.access = params[:access]        
        
        @mediaobject.save             
        logger.debug "<< Groups : #{@mediaobject.read_groups} >>"

      when 'structure'
        if !params[:commit].nil?
          rel = "Has Version"
          case params[:commit]
            when 'Sequence'
              rel = "Has Part"
            when 'Hierarchy'
              rel = "Has Part"
          end

          @mediaobject.parts.each_with_index do |master_file, index|
            @mediaobject.descMetadata.update_values({[:relation_type]=>{index=>rel}})  	
          end
        elsif !params[:masterfile_ids].nil?
          @mediaobject.parts.each_with_index do |master_file, index|
            mf_id = params[:masterfile_ids][index]
            @mediaobject.descMetadata.update_values({[:relation_identifier]=>{index=>mf_id}})  	
          end
          
          masterfiles = []
          params[:masterfile_ids].each do |mf_id|
            mf = MasterFile.find(mf_id)
            masterfiles << mf
          end
          # Inserts logic to rearrange mediaobject.parts
          #@mediaobject.parts = masterfiles
          @mediaobject.save
        end
        
        @mediaobject.save(validate: false)
        
      # When looking at the preview page use a version of the show page
      when 'preview' 
        redirect_to media_object_path(@mediaobject)
        return
    end     
      
    unless @mediaobject.errors.empty?
      report_errors
    else
      @ingest_status = update_ingest_status(params[:pid], @active_step)
      @active_step = HYDRANT_STEPS.next(@active_step).step
      
      logger.debug "<< ACTIVE STEP => #{@active_step} >>"
      logger.debug "<< INGEST STATUS => #{@ingest_status.inspect} >>"
      
      redirect_to get_redirect_path(@active_step)
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
  
  def inject_workflow_steps
    logger.debug "<< Injecting the workflow into the view >>"
    @workflow_steps = HYDRANT_STEPS
  end
  
  def update_ingest_status(pid, active_step=nil)
    logger.debug "<< UPDATE_INGEST_STATUS >>"
    logger.debug "<< Updating current ingest step >>"
    
    if @ingest_status.nil?
      @ingest_status = IngestStatus.find_or_create(pid: @mediaobject.pid)
    else
      active_step = active_step || @ingest_status.current_step
      logger.debug "<< COMPLETED : #{@ingest_status.completed?(active_step)} >>"
      logger.debug "<< PUBLISHED : #{@ingest_status.published} >>"
      
      unless (@ingest_status.published or @ingest_status.completed?(active_step))
        logger.debug "<< ADVANCING to the next step in the workflow >>"
        logger.debug "<< #{active_step} >>"
        @ingest_status.current_step = HYDRANT_STEPS.next(active_step).step
        @ingest_status.published = true if HYDRANT_STEPS.last? active_step
      end
    end

    @ingest_status.save
    @ingest_status
  end
end
