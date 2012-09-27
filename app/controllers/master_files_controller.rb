require 'net/http/digest_auth'
require 'net/http/post/multipart'
require 'rubyhorn'

class MasterFilesController < ApplicationController
  include Hydra::Controller::FileAssetsBehavior

  skip_before_filter :verify_authenticity_token, :only => [:update]
  before_filter :authenticate_user!, :only => [:update]

  # Creates and Saves a File Asset to contain the the Uploaded file 
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    if params[:container_id].nil? || MediaObject.find(params[:container_id]).nil?
      flash[:notice] = "MediaObject #{params[:container_id]} does not exist"
      redirect_to :back 
      return
    end

    media_object = MediaObject.find(params[:container_id])
    authorize! :edit, media_object, message: "You do not have sufficient privileges to add files"
    
    audio_types = ["audio/vnd.wave", "audio/mpeg", "audio/mp3", "audio/mp4", "audio/wav",
      "audio/x-wav"]
    video_types = ["application/mp4", "video/mpeg", "video/mpeg2", "video/mp4", "video/quicktime"]
    unknown_types = ["application/octet-stream", "application/x-upload-data"]
    
    format_errors = "The file was not recognized as audio or video - "
    
    if params.has_key?(:Filedata) and params.has_key?(:original)
      @master_files = []
      params[:Filedata].each do |file|
        @upload_format = 'Unknown'
        logger.debug "<< MIME type is #{file.content_type} >>"
        
        if (file.size > MasterFile::MAXIMUM_UPLOAD_SIZE)
          # Use the errors key to signal that it should be a red notice box rather
          # than the default
          flash[:errors] = "The file you have uploaded is too large"
          redirect_to :back
  
          puts "<< Redirecting - file size is too large >>"
          return
        end
        
  	    @upload_format = 'Moving image' if video_types.include?(file.content_type)
  	    @upload_format = 'Sound' if audio_types.include?(file.content_type)
  		  
  	    # If the content type cannot be inferred from the MIME type fall back on the
  	    # list of unknown types. This is different than a generic fallback because it
  	    # is skipped for known invalid extensions like application/pdf
  	    @upload_format = determine_format_by_extension(file) if unknown_types.include?(file.content_type)
  	    logger.info "<< Uploaded file appears to be #{@upload_format} >>"
  		  
  	    if 'Unknown' == @upload_format
  	      flash[:errors] = [] if flash[:errors].nil?
          error = format_errors
          error << file.original_filename
          error << " (" << file.content_type << ")"
          flash[:errors].push error
  	      next
  	    end
  		  
        @master_files << master_file = saveOriginalToHydrant(file)
        master_file.media_type = @upload_format
	
        if master_file.save
          sendOriginalToMatterhorn(master_file, file, @upload_format)
        else 
          flash[:errors] = "There was a problem storing the file"
			  end
  		end
    else
      flash[:notice] = "You must specify a file to upload"
    end
    
    respond_to do |format|
      flash[:upload] = create_upload_notice(@upload_format)
    	format.html { redirect_to edit_media_object_path(params[:container_id], step: 'file-upload') }
    	format.js { }
    end
  end
  
  def show 
    @masterfile = MasterFile.find(params[:id])
    @mediaobject = @masterfile.container
    
    authorize! :read, @mediaobject
  end

  def update
    @masterfile = MasterFile.find(params[:id])
    @mediaobject = @masterfile.container
    authorize! :edit, @mediaobject

    @masterfile.label = params[@masterfile.pid]
    @masterfile.save
  end
  
	def saveOriginalToHydrant file
		public_dir_path = "#{Rails.root}/public/"
		new_dir_path = public_dir_path + 'media_objects/' + params[:container_id].gsub(":", "_") + "/"
		new_file_path = new_dir_path + file.original_filename
		FileUtils.mkdir_p new_dir_path unless File.exists?(new_dir_path)
		FileUtils.rm new_file_path if File.exists?(new_file_path)
		FileUtils.cp file.tempfile, new_file_path

		master_file = create_master_file_from_hydrant_path(new_file_path[public_dir_path.length - 1, new_file_path.length - 1])		
    logger.debug "<< Filesize #{ file.size.to_s } >>"
    master_file.size = file.size.to_s
    
    apply_depositor_metadata(master_file)

    master_file.container = MediaObject.find(params[:container_id])

    ## Apply any posted file metadata
    unless params[:asset].nil?
      logger.debug("applying submitted file metadata: #{@sanitized_params.inspect}")
      apply_file_metadata
    end

    # If redirect_params has not been set, use {:action=>:index}
    logger.debug "Created #{master_file.pid}."
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
    
    authorize! :edit, parent, message: "You do not have sufficient privileges to delete files"

    if parent.nil?
      flash[:notice] = "MasterFile missing parent MediaObject"
      redirect_to root_path
      return
    end

    # Is this necessary with load_and_authorize_resource?
    #authorize! :edit, parent, message: "You do not have sufficient privileges to delete files"

    # parent.parts.each_with_index do |masterfile, index| 
    #   puts parent.descMetadata.relation_identifier[index].inspect
    #   if masterfile.pid.eql? parent.descMetadata.relation_identifier[index]
    #     parent.descMetadata.remove_node(:relation, index)  
    #     break  
    #   end
    # end
    # 
    # parent.remove_relationship(:has_part, master_file)
    
    parent.parts_remove master_file
    parent.save(validate: false)
    
    Rubyhorn.client.stop(master_file.source.first)

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
    format = 'Unknown'
    format = 'Moving image' if video_extensions.include?(extension)
    format = 'Sound' if audio_extensions.include?(extension)

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
