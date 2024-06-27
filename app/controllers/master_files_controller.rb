# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

# require 'avalon/controller/controller_behavior'
require 'avalon/transcript_search'

include SecurityHelper

class MasterFilesController < ApplicationController
  # include Avalon::Controller::ControllerBehavior
  include NoidValidator

  before_action :authenticate_user!, :only => [:create]
  before_action :set_masterfile_proxy, except: [:create, :oembed, :attach_structure, :delete_structure, :destroy, :update, :set_structure]
  before_action :set_masterfile, only: [:attach_structure, :delete_structure, :destroy, :update, :set_structure]
  before_action :ensure_readable_filedata, :only => [:create]
  skip_before_action :verify_authenticity_token, only: [:set_structure, :delete_structure]


  # Renders the captions content for an object or alerts the user that no caption content is present with html present
  # @return [String] The rendered template
  def captions
    authorize! :read, @master_file
    ds = @master_file.captions
    if ds.nil? || ds.empty?
      render plain: 'Not Found', status: :not_found
    else
      send_data ds.content, type: ds.mime_type, filename: ds.original_name
    end
  end

  # Renders the waveform data for an object or alerts the user that no waveform data is present with html present
  # @return [String] The rendered template
  def waveform
    authorize! :read, @master_file

    ds = params[:empty] ? WaveformService.new(8, samples_per_frame).empty_waveform(@master_file) : @master_file.waveform

    if ds.nil? || ds.empty?
      render plain: 'Not Found', status: :not_found
    else
      if request.headers['Accept-Encoding']&.include? 'deflate'
        response.headers['Content-Encoding'] = 'deflate'
        content = waveform_deflated ds
        mime_type = 'application/zlib'
      else
        content = waveform_inflated ds
        mime_type = 'application/json'
      end
      send_data content, type: mime_type, filename: ds.original_name
    end
  end

  # def can_embed?
  #   params[:action] == 'embed'
  # end

  def show
    params.permit!
    redirect_to id_section_media_object_path(@master_file.media_object_id, @master_file.id, params.except(:id, :action, :controller))
  end

  def embed
    respond_to do |format|
      format.html do
        response.headers.delete "X-Frame-Options"
        render layout: 'layouts/embed'
      end
    end
  end

  def oembed
    if params[:url].present?
      id = params[:url].split('?')[0].split('/').last
      mf = MasterFile.where(identifier_ssim: id.downcase).first
      mf ||= MasterFile.find(id) rescue nil
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
          "provider_name" => Settings.name || 'Avalon Media System',
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
    if flash.empty?
      authorize! :edit, @master_file, message: "You do not have sufficient privileges to add files"
      structure = request.format.json? ? params[:xml_content] : nil
      if params[:master_file].present? && params[:master_file][:structure].present?
        structure_file = params[:master_file][:structure]
        if structure_file.content_type != "text/xml"
          flash[:error] = "Uploaded file is not a structure xml file"
        else
          structure = structure_file.open.read
        end
      end
      if structure.present?
        validation_errors = StructuralMetadata.content_valid? structure
        if validation_errors.empty?
          @master_file.structuralMetadata.content = structure
        else
          flash[:error] = validation_errors.map{|e| "Line #{e.line}: #{e.to_s}" }
        end
      else
        @master_file.structuralMetadata.content = "<?xml version=\"1.0\"?>"
      end
      if flash.empty?
        flash[:error] = "There was a problem storing the file" unless @master_file.save
      end
    end
    respond_to do |format|
      format.html { redirect_to edit_media_object_path(@master_file.media_object_id, step: 'structure') }
      format.json { render json: {structure: ERB::Util.html_escape(structure), flash: flash} }
    end
  end

  # Creates and Saves a File Asset to contain the the Uploaded file
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    if params[:container_id].blank? || (not MediaObject.exists?(params[:container_id]))
      flash[:notice] = "MediaObject #{params[:container_id]} does not exist"
      redirect_back(fallback_location: root_path)
      return
    end

    media_object = MediaObject.find(params[:container_id])
    authorize! :edit, media_object, message: "You do not have sufficient privileges to add files"

    unless media_object.valid?
      flash[:error] = "MediaObject is invalid.  Please add required fields."
      redirect_back(fallback_location: edit_media_object_path(params[:container_id], step: 'file-upload'))
      return
    end

    begin
      result = MasterFileBuilder.build(media_object, params)
      @master_files = result[:master_files]
      [:notice, :error].each { |type| flash[type] = result[:flash][type] }
    rescue MasterFileBuilder::BuildError => err
      flash[:error] = err.message
      redirect_back(fallback_location: edit_media_object_path(params[:container_id], step: 'file-upload'))
      return
    end

    respond_to do |format|
    	format.html { redirect_to edit_media_object_path(params[:container_id], step: 'file-upload') }
    	format.js { }
    end
  end

  def update
    authorize! :update, @master_file, message: "You do not have sufficient privileges to edit files"

    @master_file.title = master_file_params[:title] if master_file_params[:title].present?
    @master_file.date_digitized = DateTime.parse(master_file_params[:date_digitized]).to_time.utc.iso8601 if master_file_params[:date_digitized].present?
    @master_file.poster_offset = master_file_params[:poster_offset] if master_file_params[:poster_offset].present?
    @master_file.permalink = master_file_params[:permalink] if master_file_params[:permalink].present?

    unless @master_file.save!
      raise Avalon::SaveError, @master_file.errors.to_a.join('<br/>')
    end

    flash[:success] = "Successfully updated."
    respond_to do |format|
      format.html { redirect_to edit_media_object_path(@master_file.media_object_id, step: 'file-upload'), success: flash[:success] }
      format.json { render json: flash[:success] }
    end
  end

  # When destroying a file asset be sure to stop it first
  def destroy
    authorize! :destroy, @master_file, message: "You do not have sufficient privileges to delete files"
    filename = File.basename(@master_file.file_location) if @master_file.file_location.present?
    filename ||= @master_file.id
    media_object_id = @master_file.media_object_id
    @master_file.destroy
    flash[:notice] = "#{filename} has been deleted from the system"
    redirect_to edit_media_object_path(media_object_id, step: "file-upload")
  end

  def set_frame
    authorize! :read, @master_file, message: "You do not have sufficient privileges to edit this file"
    opts = { :type => params[:type], :size => params[:size], :offset => params[:offset].to_f*1000, :preview => params[:preview] }
    respond_to do |format|
      format.jpeg do
        data = @master_file.extract_still(opts)
        send_data data, :filename => "#{opts[:type]}-#{@master_file.id.split(':')[1]}", :disposition => :inline, :type => 'image/jpeg'
      end
      format.all do
        @master_file.poster_offset = opts[:offset]
        unless @master_file.save
          flash[:notice] = @master_file.errors.to_a.join('<br/>')
        end
        redirect_back(fallback_location: edit_media_object_path(@master_file.media_object_id, step: "file-upload"))
      end
    end
  end

  def get_frame
    mimeType = "image/jpeg"
    content = if params[:offset]
      authorize! :edit, @master_file, message: "You do not have sufficient privileges to edit this file"
      opts = { :type => params[:type], :size => params[:size], :offset => params[:offset].to_f*1000, :preview => true }
      @master_file.extract_still(opts)
    else
      authorize! :read, @master_file, message: "You do not have sufficient privileges to view this file"
      whitelist = ["thumbnail", "poster"]
      if whitelist.include? params[:type]
        ds = @master_file.send(params[:type].to_sym)
        mimeType = ds.mime_type
        ds.content
      else
        nil
      end
    end
    if content
      send_data content, :filename => "#{params[:type]}-#{@master_file.id.split(':')[1]}", :disposition => :inline, :type => mimeType
    else
      redirect_to ActionController::Base.helpers.asset_path('audio_icon.png')
    end
  end

  def hls_manifest
    quality = params[:quality]
    if request.head?
      auth_token = request.headers['Authorization']&.sub('Bearer ', '')
      if StreamToken.valid_token?(auth_token, @master_file.id) || can?(:read, @master_file)
        return head :ok
      else
        return head :unauthorized
      end
    else
      return head :unauthorized if cannot?(:read, @master_file)
      @hls_streams = if quality == "auto"
                       gather_hls_streams(@master_file)
                     else
                       hls_stream(@master_file, quality)
                     end
    end
  end

  def structure
    authorize! :read, @master_file, message: "You do not have sufficient privileges"
    render json: @master_file.structuralMetadata.as_json
  end

  def set_structure
    # Bypass authorization check for now
    # authorize! :edit, @master_file, message: "You do not have sufficient privileges"
    @master_file.structuralMetadata.content = StructuralMetadata.from_json(params[:json])
    @master_file.save
  end

  def delete_structure
    authorize! :edit, @master_file, message: "You do not have sufficient privileges"
    @master_file.structuralMetadata.content = ''

    if @master_file.save
      flash[:success] = "Structure succesfully removed."
    else
      flash[:error] = "There was a problem removing structure."
    end
    redirect_to edit_media_object_path(@master_file.media_object_id, step: 'structure')
  end

  def iiif_auth_token
    if cannot? :read, @master_file
      head :unauthorized
    else
      message_id = params[:messageId]
      origin = params[:origin]
      access_token = StreamToken.find_or_create_session_token(session, @master_file.id)
      expires = (StreamToken.find_by(token: access_token).expires - Time.now.utc).to_i
      render 'iiif_auth_token', layout: false, locals: { message_id: message_id, origin: origin, access_token: access_token, expires: expires }
    end
  end

  def move
    current_media_object = @master_file.media_object
    authorize! :update, current_media_object
    target_media_object = MediaObject.find(params[:target])
    authorize! :update, target_media_object

    @master_file.media_object = target_media_object
    @master_file.save!
    flash[:success] = "Successfully moved master file.  See it #{view_context.link_to 'here', edit_media_object_path(target_media_object)}.".html_safe
    redirect_to edit_media_object_path(current_media_object)
  end

  def transcript
    authorize! :read, @master_file, message: "You do not have sufficient privileges"
    @supplemental_file = SupplementalFile.find(params[:t_id])
    send_data @supplemental_file.file.download, filename: @supplemental_file.file.filename.to_s, type: @supplemental_file.file.content_type, disposition: 'inline'
  end

  def download_derivative
    authorize! :download, @master_file

    begin
      high_deriv = @master_file.derivatives.find { |deriv| deriv.quality == 'high' }
      path = high_deriv.download_path

      unless FileLocator.new(path).exist?
        flash[:error] = "Unable to find or access derivative file."
        redirect_back(fallback_location: edit_media_object_path(@master_file.media_object))
        return
      end

      case path
      when /^s3:/
        # Use an AWS presigned URL to facilitate direct download of the derivative to avoid
        # having to download the file to the server as a tmp file and then sending that to
        # the client. Doing this reduces latency and server load.
        redirect_to FileLocator::S3File.new(path).download_url
      else
        send_file path, filename: File.basename(path), disposition: 'attachment'
      end
    rescue => error
      Rails.logger.error(error.class.to_s + ': ' + error.message + '\n' + error.backtrace.join('\n'))
      flash[:error] = "A problem was encountered while attempting to download derivative file. Please contact your support person if this issue persists."
      redirect_back(fallback_location: edit_media_object_path(@master_file.media_object))
    end
  end

  def search
    render json: search_response_json
  end

protected
  def set_masterfile
    if params[:id].blank? || (not MasterFile.exists?(params[:id]))
      flash[:notice] = "MasterFile #{params[:id]} does not exist"
    end
    @master_file = MasterFile.find(params[:id])
  end

  def set_masterfile_proxy
    if params[:id].blank? || SpeedyAF::Proxy::MasterFile.find(params[:id]).nil?
      flash[:notice] = "MasterFile #{params[:id]} does not exist"
    end
    @master_file = SpeedyAF::Proxy::MasterFile.find(params[:id])
  end

  # return deflated waveform content. deflate only if necessary
  def waveform_deflated(waveform)
    waveform.mime_type == 'application/zlib' ? waveform.content : Zlib::Deflate.deflate(waveform.content)
  end

  # return inflated waveform content. inflate only if necessary
  def waveform_inflated(waveform)
    waveform.mime_type == 'application/zlib' ? Zlib::Inflate.inflate(waveform.content) : waveform.content
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

  def gather_hls_streams(master_file)
    stream_info = secure_streams(master_file.stream_details, master_file.media_object_id)
    hls_streams = stream_info[:stream_hls].reject { |stream| stream[:quality] == 'auto' }
    hls_streams.each { |stream| unnest_wowza_stream(stream) } if Settings.streaming.server == "wowza"
    hls_streams
  end

  def hls_stream(master_file, quality)
    stream_info = secure_streams(master_file.stream_details, master_file.media_object_id)
    hls_stream = stream_info[:stream_hls].select { |stream| stream[:quality] == quality }
    unnest_wowza_stream(hls_stream&.first) if Settings.streaming.server == "wowza"
    hls_stream
  end

  def unnest_wowza_stream(stream)
    playlist = Avalon::M3U8Reader.read(stream[:url], recursive: false).playlist
    stream[:url] = playlist[:playlists][0]
    bandwidth = playlist["stream_inf"].match(/BANDWIDTH=(\d*)/).try(:[], 1)
    stream[:bitrate] = bandwidth if bandwidth
  end

  def master_file_params
    params.require(:master_file).permit(:title, :label, :poster_offset, :date_digitized, :permalink)
  end

  def samples_per_frame
    Settings.waveform.sample_rate * Settings.waveform.finest_zoom / Settings.waveform.player_width
  end

private

  def search_response_json
    Avalon::TranscriptSearch.new(query: params[:q], master_file: @master_file, request_url: request.url).iiif_content_search.to_json
  end
end
