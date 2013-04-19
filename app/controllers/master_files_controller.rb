# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'net/http/digest_auth'
require 'net/http/post/multipart'
require 'rubyhorn'
require 'avalon/controller/controller_behavior'

class MasterFilesController < ApplicationController
  include Avalon::Controller::ControllerBehavior

  skip_before_filter :verify_authenticity_token, :only => [:update]
  before_filter :authenticate_user!, :only => [:create]
  before_filter :ensure_readable_filedata, :only => [:create]

  # Creates and Saves a File Asset to contain the the Uploaded file 
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    if params[:container_id].blank? || (not MediaObject.exists?(params[:container_id]))
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
  
          logger.debug "<< Redirecting - file size is too large >>"
          return
        end

        master_file = MasterFile.create
        master_file.mediaobject = media_object
        master_file.setContent(file)
        MasterFilesController.set_default_item_permissions(master_file, user_key)
 
        if 'Unknown' == master_file.file_format
          flash[:errors] = [] if flash[:errors].nil?
          error = format_errors
          error << file.original_filename
          error << " (" << file.content_type << ")"
          flash[:errors].push error
          master_file.destroy
          next
        else
          flash[:upload] = create_upload_notice(master_file.file_format)
        end
	
        unless master_file.save
          flash[:errors] = "There was a problem storing the file"
        else
          media_object.save(validate: false)
          master_file.process
          @master_files << master_file
        end
        
      end
    elsif params.has_key?(:dropbox)
      @master_files = []
      params[:dropbox].each do |file|
        file_path = Avalon::DropboxService.find(file[:id])
        master_file = MasterFile.create
        master_file.mediaobject = media_object
        master_file.setContent(File.open(file_path, 'rb'))
        MasterFilesController.set_default_item_permissions(master_file, user_key)
        
        unless master_file.save
          flash[:errors] = "There was a problem storing the file"
        else
          media_object.save(validate: false)
          master_file.process
          @master_files << master_file
        end
      end
    else
      flash[:notice] = "You must specify a file to upload"
    end
    
    respond_to do |format|
    	format.html { redirect_to edit_media_object_path(params[:container_id], step: 'file-upload') }
    	format.js { }
    end
  end

  def update
    master_file = MasterFile.find(params[:id])

    if params[:workflow_id].present?
      master_file.workflow_id ||= params[:workflow_id]
      workflow = Rubyhorn.client.instance_xml(params[:workflow_id])
      master_file.update_progress!(params, workflow) 

      # If Matterhorn reports that the processing is complete then we need
      # to prepare Fedora by pulling several important values closer to the
      # interface. This will speed up searching, allow for on-the-fly quality
      # switching, and avoids hitting Matterhorn repeatedly when loading up
      # a list of search results
      if master_file.status_code.eql? 'SUCCEEDED'
        master_file.update_progress_on_success!(workflow)
      end

      # We handle the case where the item was batch ingested. If so the
      # update method needs to kick off an email letting the uploader know it is
      # ready to be previewed
      ingest_batch = IngestBatch.find_ingest_batch_by_media_object_id( master_file.mediaobject.id )
      if ingest_batch && ! ingest_batch.email_sent? && ingest_batch.finished?
        IngestBatchMailer.status_email(ingest_batch.id).deliver
        ingest_batch.email_sent = true
        ingest_batch.save!
      end
    end

    render nothing: true
  end

  # When destroying a file asset be sure to stop it first
  def destroy
    master_file = MasterFile.find(params[:id])
    parent = master_file.mediaobject
    
    authorize! :edit, parent, message: "You do not have sufficient privileges to delete files"

    filename = master_file.label
    master_file.destroy
    
    flash[:upload] = "#{filename} has been deleted from the system"

    redirect_to edit_media_object_path(parent.pid, step: "file-upload")
  end
 
  def thumbnail
    master_file = MasterFile.find(params[:id])
    parent = master_file.mediaobject
    authorize! :read, parent, message: "You do not have sufficient privileges to view this file"
    send_data master_file.thumbnail.content, :filename => "thumbnail-#{master_file.pid.split(':')[1]}", :type => master_file.thumbnail.mimeType
  end
 
  def poster
    master_file = MasterFile.find(params[:id])
    parent = master_file.mediaobject
    authorize! :read, parent, message: "You do not have sufficient privileges to view this file"
    send_data master_file.poster.content, :filename => "poster-#{master_file.pid.split(':')[1]}", :type => master_file.poster.mimeType
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

  def ensure_readable_filedata
    if params[:Filedata].present?
      params[:Filedata].each do |file|
        begin
          new_mode = File.stat(file.path).mode | 0044 # equivalent to go+r
          File.chmod(new_mode, file.path)
        rescue Exception => e
          logger.warn("Error setting permissions on #{file.path}: #{e.message}")
        end
      end
    end
  end
end
