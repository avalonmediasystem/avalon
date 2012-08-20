require 'net/http/digest_auth'
require 'net/http/post/multipart'
require 'rubyhorn'

class MasterFilesController < ApplicationController
  include Hydra::Controller::FileAssetsBehavior

    # First and simplest test - make sure that the uploaded file does not exceed the
    # limits of the system. For now this is hard coded but should probably eventually
    # be set up in a configuration file somewhere
    #
    # 250 MB is the file limit for now
    MAXIMUM_UPLOAD_SIZE = 2**20 * 250

 #  before_filter :enforce_access_controls
  load_and_authorize_resource
  skip_before_filter :verify_authenticity_token, :only => [:update]
  before_filter :authenticate_user!, :only => [:update]

  # Creates and Saves a File Asset to contain the the Uploaded file 
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    authorize! :edit, MediaObject, message: "You do not have sufficient privileges to add files"

    if params[:container_id].nil? || MediaObject.find(params[:container_id]).nil?
      flash[:notice] = "MediaObject #{params[:container_id]} does not exist"
      redirect_to :back 
      return
    end

    media_object = MediaObject.find(params[:container_id])
    
    media_object = MediaObject.find(params[:container_id])
    
    audio_types = ["audio/vnd.wave", "audio/mpeg", "audio/mp3", "audio/mp4", "audio/wav"]
    video_types = ["application/mp4", "video/mpeg", "video/mpeg2", "video/mp4", "video/quicktime"]
    unknown_types = ["application/octet-stream", "application/x-upload-data"]
    
    format_errors = "The following files were not video/audio: "
    
    if params.has_key?(:Filedata) and params.has_key?(:original)
      @master_files = []
      params[:Filedata].each do |file|
        @upload_format = 'unknown'
        logger.debug "<< MIME type is #{file.content_type} >>"
        
        if (file.size > MAXIMUM_UPLOAD_SIZE)
          # Use the errors key to signal that it should be a red notice box rather
          # than the default
          flash[:errors] = "The file you have uploaded is too large"
          redirect_to :back
  
          puts "<< Redirecting - file size is too large >>"

          return
        end
        
  	    @upload_format = 'video' if video_types.include?(file.content_type)
  	    @upload_format = 'audio' if audio_types.include?(file.content_type)
  		  
  	    # If the content type cannot be inferred from the MIME type fall back on the
  	    # list of unknown types. This is different than a generic fallback because it
  	    # is skipped for known invalid extensions like application/pdf
  	    @upload_format = determine_format_by_extension(file) if unknown_types.include?(file.content_type)
  	    logger.info "<< Uploaded file appears to be #{@upload_format} >>"
  		  
  	    if 'unknown' == @upload_format
          flash[:errors] = format_errors + file.original_filename + " "
  	      break
  	    end
  		  
        @master_files << master_file = saveOriginalToHydrant(file)
        master_file.media_type = @upload_format
        master_file.container = media_object
  			
        if master_file.save
          sendOriginalToMatterhorn(master_file, file, @upload_format)
        else 
          flash[:errors] = "Error storing file"
			  end
  		end
    else
      flash[:notice] = "You must specify a file to upload"
    end
    
    respond_to do |format|
      flash[:upload] = create_upload_notice(@upload_format)
    	format.html { redirect_to edit_media_object_path(params[:container_id], step: 'file_upload') }
    	format.js { }
    end
  end
  
	def saveOriginalToHydrant file
		public_dir_path = "#{Rails.root}/public/"
		new_dir_path = public_dir_path + 'media_objects/' + params[:container_id].gsub(":", "_") + "/"
		new_file_path = new_dir_path + file.original_filename
		FileUtils.mkdir_p new_dir_path unless File.exists?(new_dir_path)
		FileUtils.rm new_file_path if File.exists?(new_file_path)
		FileUtils.cp file.tempfile, new_file_path

		master_file = create_master_file_from_hydrant_path(new_file_path[public_dir_path.length - 1, new_file_path.length - 1])		
    
 		notice = []
    apply_depositor_metadata(master_file)

    #notice << render_to_string(:partial=>'file_assets/asset_saved_flash', :locals => { :file_asset => master_file })
    master_file.container = MediaObject.find(params[:container_id])
    master_file.container.save

      ## Apply any posted file metadata
      unless params[:asset].nil?
        logger.debug("applying submitted file metadata: #{@sanitized_params.inspect}")
        apply_file_metadata
      end

      # If redirect_params has not been set, use {:action=>:index}
      logger.debug "Created #{master_file.pid}."
      notice	
    master_file
  end

  def sendOriginalToMatterhorn(master_file, file, upload_format)
    args = {"title" => master_file.pid , "flavor" => "presenter/source", "filename" => file.original_filename}
    if upload_format == 'audio'
      args['workflow'] = "fullaudio"
    elsif upload_format == 'video'
      args['workflow'] = "hydrant"
    end
    logger.debug "<< Calling Matterhorn with arguments: #{args} >>"
    workflow_doc = Rubyhorn.client.addMediaPackage(file, args)
    flash[:notice] = "The uploaded file has been sent for processing."
    #master_file.description = "File is being processed"
    
    # I don't know why this has to be double escaped with two arrays
    master_file.source = workflow_doc.workflow.id[0]
    master_file.save
  end

	def create_master_file_from_hydrant_path(path)
		master_file = MasterFile.new
		master_file.url = path
		filename = path.split(/\//).last
		master_file.label = File.basename(filename, File.extname(filename)) 

		return master_file		
	end
	
  # When destroying a file asset be sure to stop it first
  def destroy
    master_file = MasterFile.find(params[:id])
    parent = master_file.container
    
    if !parent.nil?
      if cannot? :edit, parent.pid
        flash[:notice] = "You do not have sufficient privileges to delete files"
        redirect_to root_path
        return
      end

      parent.remove_relationship(:has_part, master_file)
      parent.save
    end
    
    logger.info "<< Stopping #{master_file.source[0]} >>"
    Rubyhorn.client.stop(master_file.source[0])
  
    filename = master_file.label
    master_file.delete
    
    flash[:upload] = "#{filename} has been deleted from the system"
    redirect_to edit_media_object_path(parent.pid, step: "file-upload")
  end
  
protected
  def determine_format_by_extension(file) 
    audio_extensions = ["mp3", "wav", "aac", "flac"]
    video_extensions = ["mpeg4", "mp4", "avi", "mov"]

    logger.debug "<< Using fallback method to guess the format >>"

    extension = file.original_filename.split(".").last.downcase
    logger.debug "<< File extension is #{extension} >>"
    
    # Default to unknown
    format = 'unknown'
    format = 'video' if video_extensions.include?(extension)
    format = 'audio' if audio_extensions.include?(extension)

    return format
  end
  
  def create_upload_notice(format) 
    case format
      when /^audio$/
       text = 'The uploaded content appears to be audio';
      when /^video$/ 
       text = 'The uploaded content appears to be video';
      else
       text = 'The uploaded content could not be identified';
	  end 
	  return text
  end
end
