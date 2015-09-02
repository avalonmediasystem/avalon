# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

  def can_embed?
    params[:action] == 'embed'
  end

  def show
    masterfile = MasterFile.find(params[:id])
    redirect_to pid_section_media_object_path(masterfile.mediaobject_id, masterfile.pid, params.except(:id, :action, :controller))
  end

  def embed
    @masterfile = MasterFile.find(params[:id])
    if can? :read, @masterfile.mediaobject
      @token = @masterfile.nil? ? "" : StreamToken.find_or_create_session_token(session, @masterfile.pid)
      @stream_info = @masterfile.stream_details(@token, default_url_options[:host])
    end
    respond_to do |format|
      format.html do
        response.headers.delete "X-Frame-Options" 
        render :layout => 'embed' 
      end
    end
  end

  def oembed
    if params[:url].present?
      pid = params[:url].split('?')[0].split('/').last
      mf = MasterFile.where("dc_identifier_tesim:\"#{pid}\"").first
      mf ||= MasterFile.find(pid) rescue nil
      if mf.present?
        width = params[:maxwidth] || MasterFile::EMBED_SIZE[:medium]
        height = mf.is_video? ? (width.to_f/mf.display_aspect_ratio.to_f).floor : MasterFile::AUDIO_HEIGHT
        maxheight = params['maxheight'].to_f
        if 0<maxheight && maxheight<height
          width = (maxheight*mf.display_aspect_ratio.to_f).floor
          height = maxheight.to_i
        end
        width = width.to_i
        hash = {
          "version" => "1.0",
          "type" => mf.is_video? ? "video" : "rich",
          "provider_name" => Avalon::Configuration.lookup('name') || 'Avalon Media System',
          "provider_url" => request.base_url,
          "width" => width,
          "height" => height,
          "html" => mf.embed_code(width, {urlappend: '/embed'})
        }
        respond_to do |format|
          format.xml  { render xml: hash.to_xml({root: 'oembed'}) }
          format.json { render json: hash }
        end
      end
    end
  end

  def attach_structure
    if params[:id].blank? || (not MasterFile.exists?(params[:id]))
      flash[:notice] = "MasterFile #{params[:id]} does not exist"
    end
    @masterfile = MasterFile.find(params[:id])
    unless flash.empty? and  MediaObject.exists?(@masterfile.mediaobject_id)
      flash[:notice] = "MediaObject #{@masterfile.mediaobject_id} does not exist"
    end
    if flash.empty?
      media_object = MediaObject.find(@masterfile.mediaobject_id)
      authorize! :edit, media_object, message: "You do not have sufficient privileges to add files"
      structure = request.format.json? ? params[:xml_content] : nil
      if params[:master_file].present? && params[:master_file][:structure].present?
        structure = params[:master_file][:structure].open.read
      end
      if structure.present?
        validation_errors = StructuralMetadata.content_valid? structure
        if validation_errors.empty?
          @masterfile.structuralMetadata.content = structure
        else
          flash[:error] = validation_errors.map{|e| "Line #{e.line}: #{e.to_s}" }
        end
      else
        @masterfile.structuralMetadata.delete
      end
      if flash.empty?
        flash[:error] = "There was a problem storing the file" unless @masterfile.save
      end
    end
    respond_to do |format|
      format.html { redirect_to edit_media_object_path(@masterfile.mediaobject_id, step: 'structure') }
      format.json { render json: {structure: structure, flash: flash} }
    end
  end

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
        if (file.size > MasterFile::MAXIMUM_UPLOAD_SIZE)
          # Use the errors key to signal that it should be a red notice box rather
          # than the default
          flash[:error] = "The file you have uploaded is too large"
          redirect_to :back
          return
        end

        master_file = MasterFile.new
        master_file.save( validate: false )
        master_file.mediaobject = media_object
        master_file.setContent(file)
        master_file.set_workflow(params[:workflow])

        if 'Unknown' == master_file.file_format
          flash[:error] = [] if flash[:error].nil?
          error = format_errors
          error << file.original_filename
          error << " (" << file.content_type << ")"
          flash[:error].push error
          master_file.destroy
          next
        else
          flash[:notice] = create_upload_notice(master_file.file_format)
        end
	
        unless master_file.save
          flash[:error] = "There was a problem storing the file"
        else
          media_object.save(validate: false)
          master_file.process
          @master_files << master_file
        end
        
      end
    elsif params.has_key?(:selected_files)
      @master_files = []
      params[:selected_files].each_value do |entry|
        file_path = URI.parse(entry[:url]).path.gsub(/\+/,' ')
        master_file = MasterFile.new
        master_file.save( validate: false )
        master_file.mediaobject = media_object
        master_file.setContent(File.open(file_path, 'rb'))
        master_file.set_workflow(params[:workflow])
        
        unless master_file.save
          flash[:error] = "There was a problem storing the file"
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

  # When destroying a file asset be sure to stop it first
  def destroy
    master_file = MasterFile.find(params[:id])
    media_object = master_file.mediaobject
    
    authorize! :edit, media_object, message: "You do not have sufficient privileges to delete files"

    filename = File.basename(master_file.file_location)
    master_file.destroy

    media_object.set_media_types!
    media_object.set_duration!
    media_object.save( validate: false )
    
    flash[:notice] = "#{filename} has been deleted from the system"

    redirect_to edit_media_object_path(media_object.pid, step: "file-upload")
  end
 
  def set_frame
    master_file = MasterFile.find(params[:id])
    parent = master_file.mediaobject
    
    authorize! :read, parent, message: "You do not have sufficient privileges to edit this file"
    opts = { :type => params[:type], :size => params[:size], :offset => params[:offset].to_f*1000, :preview => params[:preview] }
    respond_to do |format|
      format.jpeg do
        data = master_file.extract_still(opts)
        send_data data, :filename => "#{opts[:type]}-#{master_file.pid.split(':')[1]}", :disposition => :inline, :type => 'image/jpeg'
      end
      format.all do
        master_file.poster_offset = opts[:offset]
        unless master_file.save
          flash[:notice] = master_file.errors.to_a.join('<br/>')
        end
        redirect_to edit_media_object_path(parent.pid, step: "file-upload")
      end
    end
  end

  def get_frame
    master_file = MasterFile.find(params[:id])
    parent = master_file.mediaobject
    mimeType = "image/jpeg"
    content = if params[:offset]
      authorize! :edit, parent, message: "You do not have sufficient privileges to view this file"
      opts = { :type => params[:type], :size => params[:size], :offset => params[:offset].to_f*1000, :preview => true }
      master_file.extract_still(opts)
    else
      authorize! :read, parent, message: "You do not have sufficient privileges to view this file"
      ds = master_file.datastreams[params[:type]]
      mimeType = ds.mimeType
      ds.content
    end
    send_data content, :filename => "#{params[:type]}-#{master_file.pid.split(':')[1]}", :disposition => :inline, :type => mimeType
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
