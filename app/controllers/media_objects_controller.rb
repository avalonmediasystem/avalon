# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

require 'avalon/controller/controller_behavior'
require 'avalon/intercom'

class MediaObjectsController < ApplicationController
  include Rails::Pagination
  include Avalon::Workflow::WorkflowControllerBehavior
  include Avalon::Controller::ControllerBehavior
  include ConditionalPartials
  include NoidValidator
  include SecurityHelper

  before_action :authenticate_user!, except: [:show, :set_session_quality, :show_stream_details, :manifest]
  before_action :load_resource, except: [:create, :destroy, :update_status, :set_session_quality, :tree, :deliver_content, :confirm_remove, :show_stream_details, :add_to_playlist, :intercom_collections, :manifest, :move_preview, :edit, :update, :json_update]
  load_and_authorize_resource except: [:create, :destroy, :update_status, :set_session_quality, :tree, :deliver_content, :confirm_remove, :show_stream_details, :add_to_playlist, :intercom_collections, :manifest, :move_preview, :show_progress]
  authorize_resource only: [:create]

  before_action :inject_workflow_steps, only: [:edit, :update], unless: proc { request.format.json? }
  before_action :load_player_context, only: [:show]

  def self.is_editor ctx
    Rails.cache.fetch([ctx.hash, :is_editor], expires_in: 5.seconds) do
      ctx.current_ability.is_editor_of?(ctx.instance_variable_get('@media_object').collection)
    end
  end
  def self.is_lti_session ctx
    ctx.user_session.present? && ctx.user_session[:lti_group].present?
  end

  is_editor_or_not_lti = proc { |ctx| self.is_editor(ctx) || !self.is_lti_session(ctx) }
  is_editor_or_lti = proc { |ctx| (Avalon::Authentication::Providers.any? {|p| p[:provider] == :lti } && self.is_editor(ctx)) || self.is_lti_session(ctx) }

  add_conditional_partial :share, :share, partial: 'share_resource', if: is_editor_or_not_lti
  add_conditional_partial :share, :embed, partial: 'embed_resource', if: is_editor_or_not_lti
  add_conditional_partial :share, :lti_url, partial: 'lti_url',  if: is_editor_or_lti

  def can_embed?
    params[:action] == 'show'
  end

  def confirm_remove
    raise CanCan::AccessDenied unless Array(params[:id]).any? { |id| current_ability.can? :destroy, MediaObject.find(id) }
  end

  def intercom_collections
    reload = params['reload'] == 'true'
    collections = session[:intercom_collections]
    if reload || collections.blank?
      intercom = Avalon::Intercom.new(user_key)
      collections = intercom.user_collections
      session[:intercom_collections] = collections
    end
    collections.each do |c|
      c['default'] = c['id'] == session[:intercom_default_collection]
    end
    respond_to do |format|
      format.json do
        render json: collections.to_json
      end
    end
  end

  def intercom_push
    if can? :intercom_push, @media_object
      intercom = Avalon::Intercom.new(user_key)
      collections = intercom.user_collections(true)
      session[:intercom_collections] = collections
      result = intercom.push_media_object(@media_object, params[:collection_id], params[:include_structure] == 'true')
      if result[:link].present?
        session[:intercom_default_collection] = params[:collection_id]
        target_link = view_context.link_to('See it here.', result[:link], target: '_blank')
        flash[:success] = view_context.safe_join(["The item was pushed successfully. ", target_link])
        flash[:alert] = result[:message] if result[:message].present?
      elsif result[:status].present?
        flash[:alert] = "There was an error pushing the item. (#{result[:status]}: #{result[:message]})"
      else
        flash[:alert] = result[:message]
      end
    else
      flash[:alert] = 'You do not have permission to push this media object.'
    end
    redirect_to media_object_path(@media_object.id)
  end

  def new
    collection = Admin::Collection.find(params[:collection_id])
    authorize! :read, collection

    @media_object = MediaObjectsController.initialize_media_object(user_key)
    @media_object.workflow.origin = 'web'
    @media_object.collection = collection
    @media_object.save(:validate => false)

    redirect_to edit_media_object_path(@media_object)
  end

  # POST /media_objects/avalon:1/add_to_playlist
  def add_to_playlist
    @media_object = SpeedyAF::Proxy::MediaObject.find(params[:id])
    authorize! :read, @media_object
    masterfile_id = params[:post][:masterfile_id]
    playlist_id = params[:post][:playlist_id]
    playlist = Playlist.find(playlist_id)
    if current_ability.cannot? :update, playlist
      render json: {message: "<p>You are not authorized to update this playlist.</p>", status: 403}, status: 403 and return
    end
    playlistitem_scope = params[:post][:playlistitem_scope] #'section', 'structure'
    # If a single masterfile_id wasn't in the request, then create playlist_items for all masterfiles
    masterfile_ids = masterfile_id.present? ? [masterfile_id] : @media_object.ordered_master_file_ids
    masterfile_ids.each do |mf_id|
      mf = SpeedyAF::Proxy::MasterFile.find(mf_id)
      if playlistitem_scope=='structure' && mf.has_structuralMetadata? && mf.structuralMetadata.xpath('//Span').present?
        #create individual items for spans within structure
        mf.structuralMetadata.xpath('//Span').each do |s|
          labels = [mf.embed_title]
          labels += s.xpath('ancestor::Div[\'label\']').collect{|a|a.attribute('label').value.strip}
          labels << s.attribute('label')
          label = labels.reject(&:blank?).join(' - ')
          start_time = s.attribute('begin')
          end_time = s.attribute('end')
          start_time = time_str_to_milliseconds(start_time.value) if start_time.present?
          end_time = time_str_to_milliseconds(end_time.value) if end_time.present?
          clip = AvalonClip.new(title: label, master_file: mf, start_time: start_time, end_time: end_time)
          new_item = PlaylistItem.new(clip: clip, playlist: playlist)
          playlist.items += [new_item]
        end
      else
        #create a single item for the entire masterfile
        item_title = @media_object.master_file_ids.count>1? mf.embed_title : @media_object.title
        clip = AvalonClip.new(title: item_title, master_file: mf)
        playlist.items += [PlaylistItem.new(clip: clip, playlist: playlist)]
      end
    end
    link = view_context.link_to('View Playlist', playlist_path(playlist), class: "btn btn-primary btn-sm")
    render json: {message: "<p>Playlist items created successfully.</p> #{link}", status: 200}
  end

  # POST /media_objects
  def create
    @media_object = MediaObjectsController.initialize_media_object(user_key)
    # Preset the workflow to the last workflow step to ensure validators run
    @media_object.workflow.last_completed_step = HYDRANT_STEPS.last.step
    update_media_object
  end

  # PUT /media_objects/avalon:1.json
  def json_update
    # Preset the workflow to the last workflow step to ensure validators run
    @media_object.workflow.last_completed_step = HYDRANT_STEPS.last.step
    update_media_object
  end

  def update_media_object
    if (api_params[:collection_id].present?)
      begin
        collection = Admin::Collection.find(api_params[:collection_id])
      rescue ActiveFedora::ObjectNotFoundError
        render json: { errors: ["Collection not found for #{api_params[:collection_id]}"] }, status: 422
        return
      end

      @media_object.collection = collection
    end

    @media_object.avalon_uploader = 'REST API'

    populate_from_catalog = (!!api_params[:import_bib_record] && media_object_parameters[:bibliographic_id].present?)
    if populate_from_catalog && Avalon::BibRetriever.configured?(media_object_parameters[:bibliographic_id][:source])
      begin
        # Set other identifiers
        # FIXME: The ordering in the slice is important
        @media_object.update_attributes(media_object_parameters.slice(:other_identifier, :other_identifier_type, :identifier))
        # Try to use Bib Import
        @media_object.descMetadata.populate_from_catalog!(media_object_parameters[:bibliographic_id][:id],
                                                          media_object_parameters[:bibliographic_id][:source])
      rescue
        bib_id = media_object_parameters.dig(:bibliographic_id, :id) || ''
        bib_source = media_object_parameters.dig(:bibliographic_id, :source) || ''
        logger.warn "Failed bib import using bibID #{bib_id}, #{bib_source}"
      ensure
        unless @media_object.valid?
          # Fall back to MODS as sent if Bib Import fails
          @media_object.update_attributes(media_object_parameters.slice(*@media_object.errors.attribute_names)) if params.has_key?(:fields) and params[:fields].respond_to?(:has_key?)
        end
      end
    else
      @media_object.update_attributes(media_object_parameters) if params.has_key?(:fields) and params[:fields].respond_to?(:has_key?)
    end

    error_messages = []
    unless @media_object.valid?
      invalid_fields = @media_object.errors.attribute_names
      required_fields = [:title, :date_issued]
      unless required_fields.any? { |f| invalid_fields.include? f }
        invalid_fields.each do |field|
          #NOTE this will erase all values for fields with multiple values
          bib_id = media_object_parameters.dig(:bibliographic_id, :id) || ''
          logger.warn "Erasing field #{field} with bad value, bibID: #{bib_id}, avalon ID: #{@media_object.id}"
          @media_object.send("#{field}=", nil)
        end
      end
    end
    if !@media_object.save
      error_messages += ['Failed to create media object:']+@media_object.errors.full_messages
    elsif master_files_params.respond_to?('each')
      old_ordered_master_files = @media_object.ordered_master_files.to_a.collect(&:id)
      master_files_params.each_with_index do |file_spec, index|
        master_file = MasterFile.new(file_spec.except(:structure, :captions, :captions_type, :files, :other_identifier, :label, :date_digitized))
        # master_file.media_object = @media_object
        master_file.structuralMetadata.content = file_spec[:structure] if file_spec[:structure].present?
        if file_spec[:captions].present?
          master_file.captions.content = file_spec[:captions].encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: '')
          master_file.captions.mime_type = file_spec[:captions_type]
        end
        # TODO: This inconsistency should eventually be addressed by updating the API
        master_file.title = file_spec[:label] if file_spec[:label].present?
        master_file.date_digitized = DateTime.parse(file_spec[:date_digitized]).to_time.utc.iso8601 if file_spec[:date_digitized].present?
        master_file.identifier += Array(params[:files][index][:other_identifier])
        master_file.comment += Array(params[:files][index][:comment])
        master_file._media_object = @media_object
        if file_spec[:files].present?
          if master_file.update_derivatives(file_spec[:files], false)
            master_file.update_stills_from_offset!
            WaveformJob.perform_later(master_file.id)
            @media_object.ordered_master_files += [master_file]
          else
            file_location = file_spec.dig(:file_location) || '<unknown>'
            message = "Problem saving MasterFile for #{file_location}:"
            error_messages += [message]
            error_messages += master_file.errors.full_messages
            break
          end
        end
      end

      if error_messages.empty?
        if api_params[:replace_masterfiles]
          old_ordered_master_files.each do |mf|
            p = MasterFile.find(mf)
            @media_object.master_files.delete(p)
            @media_object.ordered_master_files.delete(p)
            p.destroy
          end
        end

        #Ensure these are set because sometimes there is a timing issue that prevents the masterfile save from doing it
        @media_object.set_media_types!
        @media_object.set_resource_types!
        @media_object.set_duration!
        @media_object.workflow.last_completed_step = HYDRANT_STEPS.last.step
        if !@media_object.save
          error_messages += ['Failed to create media object:']+@media_object.errors.full_messages
        else
          if !!api_params[:publish]
            @media_object.publish!('REST API')
            @media_object.workflow.publish
          else
            @media_object.publish!('')
          end
        end
      end
    end
    if error_messages.empty?
      render json: {id: @media_object.id}, status: 200
    else
      logger.warn "update_media_object failed for #{params[:fields][:title] rescue '<unknown>'}: #{error_messages}"
      render json: {errors: error_messages}, status: 422
      @media_object.destroy unless action_name == 'json_update'
    end
  end

  def custom_edit
    if ['preview', 'structure', 'file-upload'].include? @active_step
      @masterFiles = load_master_files
    end

    if 'preview' == @active_step
      load_current_stream
    end

    if 'access-control' == @active_step
      @groups = @media_object.local_read_groups
      @group_leases = @media_object.leases('local')
      @users = @media_object.read_users
      @user_leases = @media_object.leases('user')
      @virtual_groups = @media_object.virtual_read_groups
      @virtual_leases = @media_object.leases('external')
      @ip_groups = @media_object.ip_read_groups
      @ip_leases = @media_object.leases('ip')
      @visibility = @media_object.visibility

      @addable_groups = Admin::Group.non_system_groups.reject { |g| @groups.include? g.name }
      @addable_courses = Course.all.reject { |c| @virtual_groups.include? c.context_id }
    end
  end

  def custom_update
    flash[:notice] = @notice
  end

  def index
    mos = paginate MediaObject.accessible_by(current_ability, :index)
    render json: mos.to_a.collect { |mo| mo.as_json(include_structure: params[:include_structure] == "true") }
  end

  def show
    respond_to do |format|
      format.html do
        if (not @masterFiles.empty? and @currentStream.blank?) then
          redirect_to media_object_path(@media_object.id), flash: { notice: 'That stream was not recognized. Defaulting to the first available stream for the resource' }
        else
          render
        end
      end
      format.json do
        response_json = @media_object.as_json(include_structure: params[:include_structure] == "true")
        response_json.except!(:files, :visibility, :read_groups) unless current_ability.can? :edit, @media_object
        render json: response_json.to_json
      end
    end
  end

  def show_stream_details
    load_current_stream
    authorize! :read, @currentStream
    render json: @currentStreamInfo
  end

  def show_progress
    authorize! :read, @media_object
    overall = { :success => 0, :error => 0 }
    encode_gids = master_file_presenters.collect { |mf| "gid://ActiveEncode/#{mf.encoder_class}/#{mf.workflow_id}" }
    result = Hash[
      ActiveEncode::EncodeRecord.where(global_id: encode_gids).collect do |encode|
        raw_encode = JSON.parse(encode.raw_object)
        status = encode.state.to_s.upcase
        mf_status = {
          status: status,
          complete: encode.progress.to_i,
          success: encode.progress.to_i,
          operation: raw_encode['current_operations']&.first,
          message: raw_encode['errors'].first.try(:sub, /^.+:/, '')
        }
        if status == 'FAILED'
          mf_status[:error] = 100 - mf_status[:success]
          overall[:error] += 100
        else
          mf_status[:error] = 0
          overall[:success] += mf_status[:complete]
        end
        [encode.master_file_id, mf_status]
      end
    ]
    master_files_count = @media_object.master_files.size
    if master_files_count > 0
      overall.each { |k,v| overall[k] = [0,[100,v.to_f/master_files_count.to_f].min].max.floor }
    else
      overall = {success: 0, error: 0}
    end

    if overall[:success]+overall[:error] > 100
      overall[:error] = 100-overall[:success]
    end

    result['overall'] = overall
    respond_to do |format|
      format.any(:xml, :json) { render request.format.to_sym => result }
    end
  end

  def destroy
    errors = []
    success_count = 0
    success_ids = []
    Array(params[:id]).each do |id|
      media_object = MediaObject.find(id)
      if can? :destroy, media_object
        success_ids << id
        success_count += 1
      else
        errors += [ "#{media_object.title} (#{params[:id]}) permission denied" ]
      end
    end
    message = "#{success_count} #{'media object'.pluralize(success_count)} deleted."
    message += "These objects were not deleted:</br> #{ errors.join('<br/> ') }" if errors.count > 0
    BulkActionJobs::Delete.perform_later success_ids, nil
    redirect_to params[:previous_view]=='/bookmarks'? '/bookmarks' : root_path, flash: { notice: message }
  end

  # Sets the published status for the object. If no argument is given then
  # it will just toggle the state.
  def update_status
    status = params[:status]
    errors = []
    success_count = 0
    Array(params[:id]).each do |id|
      media_object = MediaObject.find(id)
      if cannot? :update, media_object
        errors += ["#{media_object&.title} (#{id}) (permission denied)."]
      else
        begin
          case status
          when 'publish'
            unless media_object.title.present? && media_object.date_issued.present?
              errors += ["#{media_object&.title} (#{id}) (missing required fields)"]
              next
            end
            media_object.publish!(user_key)
            # additional save to set permalink
            media_object.save( validate: false )
            success_count += 1
          when 'unpublish'
            if can? :unpublish, media_object
              media_object.publish!(nil, validate: false)
              success_count += 1
            else
              errors += ["#{media_object&.title} (#{id}) (permission denied)."]
            end
          end
        rescue ActiveFedora::RecordInvalid => e
          errors += [e.message]
        end
      end
    end
    message = "#{success_count} #{'media object'.pluralize(success_count)} successfully #{status}ed." if success_count.positive?
    message = "Unable to #{status} #{'item'.pluralize(errors.count)}: #{ errors.join('<br/> ') }" if errors.count > 0
    redirect_back(fallback_location: root_path, flash: {notice: message.html_safe})
  end

  # Sets the published status for the object. If no argument is given then
  # it will just toggle the state.
  def tree
    @media_object = SpeedyAF::Proxy::MediaObject.find(params[:id])
    authorize! :inspect, @media_object

    respond_to do |format|
      format.html {
        render 'tree', :layout => !request.xhr?
      }
      format.json {
        result = { @media_object.id => {} }
        @media_object.indexed_master_files.each do |mf|
          result[@media_object.id][mf.id] = mf.derivatives.collect(&:id)
        end
        render :json => result
      }
    end
  end

  def manifest
    @media_object = SpeedyAF::Proxy::MediaObject.find(params[:id])
    authorize! :read, @media_object

    master_files = master_file_presenters
    canvas_presenters = master_files.collect do |mf|
      stream_info = secure_streams(mf.stream_details, @media_object.id)
      IiifCanvasPresenter.new(master_file: mf, stream_info: stream_info)
    end
    presenter = IiifManifestPresenter.new(media_object: @media_object, master_files: canvas_presenters, lending_enabled: lending_enabled?(@media_object))

    manifest = IIIFManifest::V3::ManifestFactory.new(presenter).to_h
    # TODO: implement thumbnail in iiif_manifest
    manifest["thumbnail"] = [{ "id" => presenter.thumbnail, "type" => 'Image' }] if presenter.thumbnail

    respond_to do |wants|
      wants.json { render json: manifest.to_json }
      wants.html { render json: manifest.to_json }
    end
  end

  def self.initialize_media_object( user_key )
    media_object = MediaObject.new( avalon_uploader: user_key )

    media_object
  end

  def build_context
    params.merge!({media_object: model_object, media_object_params: media_object_parameters, user: user_key, ability: current_ability})
  end

  def set_session_quality
    session[:quality] = params[:quality] if params[:quality].present?
    head :ok
  end

  def move_preview
    @media_object = MediaObject.find(params[:id])
    authorize! :update, @media_object
    preview = {
      id: @media_object.id,
      title: @media_object.title,
      collection: @media_object.collection.name,
      main_contributors: @media_object.creator,
      publication_date: @media_object.date_created,
      published_by: @media_object.avalon_publisher,
      published: @media_object.published?,
    }

    respond_to do |wants|
      wants.json { render json: preview }
    end
  end

  rescue_from Avalon::VocabularyNotFound do |exception|
    support_email = Settings.email.support
    notice_text = I18n.t('errors.controlled_vocabulary_error') % [exception.message, support_email, support_email]
    redirect_to root_path, flash: { error: notice_text.html_safe }
  end

  protected

  def load_resource
    @media_object = SpeedyAF::Proxy::MediaObject.find(params[:id])
  end

  def master_file_presenters
    # Assume that @media_object is a SpeedyAF::Proxy::MediaObject
    @media_object.ordered_master_files
  end

  def load_master_files(mode = :rw)
    @masterFiles ||= mode == :rw ? @media_object.indexed_master_files.to_a : master_file_presenters
  end

  def set_player_token
    @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.id)
  end

  def load_current_stream
    set_active_file
    set_player_token
    @currentStreamInfo = if params[:id]
                           @currentStream.nil? ? {} : secure_streams(@currentStream.stream_details, params[:id])
                         else
                           @currentStream.nil? ? {} : secure_streams(@currentStream.stream_details, @media_object.id)
                         end
    @currentStreamInfo['t'] = view_context.parse_media_fragment(params[:t]) # add MediaFragment from params
    @currentStreamInfo['lti_share_link'] = view_context.lti_share_url_for(@currentStream)
    @currentStreamInfo['link_back_url'] = view_context.share_link_for(@currentStream)
  end

  def load_player_context
    return if request.format.json? and !params.has_key? :content

    if params[:part]
      index = params[:part].to_i-1
      if index < 0 or index > @media_object.master_files.size-1
        raise ActiveFedora::ObjectNotFoundError
      end
      params[:content] = @media_object.indexed_master_file_ids[index]
    end

    load_master_files(mode: :ro)
    load_current_stream
  end

  # The goal of this method is to determine which stream to provide to the interface
  #
  # for immediate playback. Eventually this might be replaced by an AJAX call but for
  # now to update the stream you must do a full page refresh.
  #
  # If the stream is not a member of that media object or does not exist at all then
  # return a nil value that needs to be handled appropriately by the calling code
  # block
  def set_active_file
    @currentStream ||= if params[:content]
      begin
        MasterFile.find(params[:content])
      rescue ActiveFedora::ObjectNotFoundError
        flash[:notice] = "That stream was not recognized. Defaulting to the first available stream for the resource"
        redirect_to media_object_path(@media_object.id)
        nil
      end
    end
    if @currentStream.nil?
      @currentStream = @media_object.indexed_master_files.first
    end
    return @currentStream
  end

  def media_object_parameters
    # TODO: Restrist permitted params!!!
    # params.require(:fields).permit!
    # params.permit!
    params[:fields] ||= {}
    params[:fields].permit!
    params[:media_object] ||= {}
    params[:media_object].permit!
    mo_parameters = params[:fields].merge(params[:media_object])
    # NOTE: Deal with multi-part fields
    #Bib ids
    bib_id = mo_parameters.delete(:bibliographic_id)
    bib_id_label = mo_parameters.delete(:bibliographic_id_label)
    mo_parameters[:bibliographic_id] = { id: bib_id, source: bib_id_label } if bib_id.present?
    #Related urls
    related_item_url = mo_parameters.delete(:related_item_url) || []
    related_item_label = mo_parameters.delete(:related_item_label) || []
    mo_parameters[:related_item_url] = related_item_url.zip(related_item_label).map{|a|{url: a[0],label: a[1]}}
    #Other identifiers
    other_identifier = mo_parameters.delete(:other_identifier) || []
    other_identifier_type = mo_parameters.delete(:other_identifier_type) || []
    mo_parameters[:other_identifier] = other_identifier.zip(other_identifier_type).map{|a|{id: a[0], source: a[1]}}
    #Notes
    note = mo_parameters.delete(:note) || []
    note_type = mo_parameters.delete(:note_type) || []
    mo_parameters[:note] = note.zip(note_type).map{|a|{note: a[0],type: a[1]}}

    mo_parameters
  end

  def master_files_params
    params.permit(:files => [:file_location,
                             :title,
                             :label,
                             :file_location,
                             :file_checksum,
                             :file_size,
                             :duration,
                             :display_aspect_ratio,
                             :original_frame_size,
                             :file_format,
                             :poster_offset,
                             :thumbnail_offset,
                             :date_digitized,
                             :structure,
                             :captions,
                             :captions_type,
                             :workflow_name,
                             :workflow_id,
                             # :percent_complete,
                             # :percent_succeeded,
                             # :percent_failed,
                             # :status_code,
                             :other_identifier,
                             :structure,
                             :physical_description,
                             :width,
                             :height,
                             files: [:label,
                                     :id,
                                     :url,
                                     :hls_url,
                                     :duration,
                                     :mime_type,
                                     :audio_bitrate,
                                     :audio_codec,
                                     :video_bitrate,
                                     :video_codec,
                                     :width,
                                     :height,
                                     :location,
                                     :track_id,
                                     :hls_track_id,
                                     :managed,
                                     :derivativeFile]])[:files]
  end

  def api_params
    params.permit(:collection_id, :publish, :import_bib_record, :replace_masterfiles)
  end
end
