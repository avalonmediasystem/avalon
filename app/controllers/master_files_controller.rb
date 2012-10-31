require 'net/http/digest_auth'
require 'net/http/post/multipart'
require 'rubyhorn'

class MasterFilesController < ApplicationController
#  include Hydra::Controller::FileAssetsBehavior

  skip_before_filter :verify_authenticity_token, :only => [:update]
  before_filter :authenticate_user!, :only => [:create]

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
    
    format_errors = "The file was not recognized as audio or video - "
    
    if params.has_key?(:Filedata) and params.has_key?(:original)
      @master_files = []
      params[:Filedata].each do |file|
        logger.debug "<< MIME type is #{file.content_type} >>"
        
        if (file.size > MasterFile::MAXIMUM_UPLOAD_SIZE)
          # Use the errors key to signal that it should be a red notice box rather
          # than the default
          flash[:errors] = "The file you have uploaded is too large"
          redirect_to :back
  
          puts "<< Redirecting - file size is too large >>"
          return
        end

        master_file = MasterFile.new
        master_file.container = media_object
        master_file.setContent(file)
        
        if 'Unknown' == master_file.media_type
          flash[:errors] = [] if flash[:errors].nil?
          error = format_errors
          error << file.original_filename
          error << " (" << file.content_type << ")"
          flash[:errors].push error
	  master_file.destroy
          next
        end

        @master_files << master_file
	
        if master_file.save
          master_file.process
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

  def update
    @masterfile = MasterFile.find(params[:id])
    if params[:workflow_id].present?
      puts "Matterhorn called!"
      @masterfile.updateProgress    
    else
      @mediaobject = @masterfile.container
      authorize! :edit, @mediaobject
      @masterfile.label = params[@masterfile.pid]
    end
    @masterfile.save
    render :nothing => true
  end

  # When destroying a file asset be sure to stop it first
  def destroy
    master_file = MasterFile.find(params[:id])
    parent = master_file.container
    
    authorize! :edit, parent, message: "You do not have sufficient privileges to delete files"

    filename = master_file.label
    master_file.destroy
    
    flash[:upload] = "#{filename} has been deleted from the system"

    redirect_to edit_media_object_path(parent.pid, step: "file-upload")
  end
  
protected
  def create_upload_notice(format) 
    case format
      when /^Sound$/
       text = 'The uploaded content appears to be audio';
      when /^Moving image$/ 
       text = 'The uploaded content appears to be video';
      else
       text = 'The uploaded content could not be identified';
      end 
    return text
  end
end
