require 'net/http/digest_auth'
require 'net/http/post/multipart'
require 'rubyhorn'
require 'hydrant/controller/controller_behavior'

class MasterFilesController < ApplicationController
  include Hydrant::Controller::ControllerBehavior

  skip_before_filter :verify_authenticity_token, :only => [:update]
  before_filter :authenticate_user!, :only => [:create]

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
  
          puts "<< Redirecting - file size is too large >>"
          return
        end

        master_file = MasterFile.new
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
          master_file.process
          @master_files << master_file
        end
        
      end
    elsif params.has_key?(:dropbox)
      @master_files = []
      params[:dropbox].each do |file|
        file_path = Hydrant::DropboxService.find(file[:id])
        master_file = MasterFile.new
        master_file.mediaobject = media_object
        master_file.setContent(File.open(file_path, 'rb'))
        set_default_item_permissions master_file
        
        unless master_file.save
          flash[:errors] = "There was a problem storing the file"
        else
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
    @masterfile = MasterFile.find(params[:id])
    if params[:workflow_id].present?
      @masterfile.workflow_id ||= params[:workflow_id]
      workflow = Rubyhorn.client.instance_xml(params[:workflow_id])
      @masterfile.updateProgress workflow 
      if @masterfile.status_code.eql? "SUCCEEDED"
        workflow.ng_xml.xpath('//xmlns:workflow/ns3:mediapackage/ns3:media/ns3:track[@type="presenter/delivery" and ns3:tags/ns3:tag = "streaming"]/@id', workflow.ng_xml.root.namespaces).each do |trackid|
          Derivative.create_from_master_file(@masterfile, trackid.content)
        end

        @masterfile.mediapackage_id = workflow.mediapackage.id.first
        sourceelement = workflow.ng_xml.xpath('//xmlns:workflow/ns3:mediapackage/ns3:media/ns3:track[@type="presenter/source"]').first
        @masterfile.file_checksum = sourceelement.at('./ns3:checksum').content
        @masterfile.duration = sourceelement.at('./ns3:duration').content
        thumbnailelement = workflow.ng_xml.xpath('//xmlns:workflow/ns3:mediapackage/ns3:attachments/ns3:attachment[@type="presenter/search+preview"]').first
	unless thumbnailelement.nil?
          thumbnailuri = URI.parse(thumbnailelement.at('./ns3:url').content)
          @masterfile.thumbnail.content = Rubyhorn.client.get(thumbnailuri.path[1..-1]) #need to string leading slash for rubyhorn to be happy
          @masterfile.thumbnail.mimeType = thumbnailelement.at('./ns3:mimetype').content
        end
        posterelement = workflow.ng_xml.xpath('//xmlns:workflow/ns3:mediapackage/ns3:attachments/ns3:attachment[@type="presenter/player+preview"]').first
	unless posterelement.nil?
          posteruri = URI.parse(posterelement.at('./ns3:url').content)
          @masterfile.poster.content = Rubyhorn.client.get(posteruri.path[1..-1])
          @masterfile.poster.mimeType = posterelement.at('./ns3:mimetype').content
        end
        @masterfile.save
      end

      ingest_batch = IngestBatch.find_ingest_batch_by_media_object_id( @masterfile.mediaobject.id )
      if ingest_batch && ! ingest_batch.email_sent? && ingest_batch.finished?
        IngestBatchMailer.status_email(ingest_batch.id).deliver
        ingest_batch.email_sent = true
        ingest_batch.save!
      end

    else
      @mediaobject = @masterfile.mediaobject
      authorize! :edit, @mediaobject
      @masterfile.label = params[@masterfile.pid]
    end
    @masterfile.save
    render :nothing => true
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
