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

require 'avalon/controller/controller_behavior'

class MediaObjectsController < ApplicationController
  include Avalon::Workflow::WorkflowControllerBehavior
  include Avalon::Controller::ControllerBehavior
  include ConditionalPartials

  before_filter :authenticate_user!, except: [:show, :set_session_quality]
  before_filter :authenticate_api!, only: [:show], if: proc{|c| request.format.json?}
  load_and_authorize_resource except: [:destroy, :update_status, :set_session_quality, :tree, :deliver_content]
  # authorize_resource only: [:create, :update]

  before_filter :inject_workflow_steps, only: [:edit, :update], unless: proc{|c| request.format.json?}
  before_filter :load_player_context, only: [:show]

  def self.is_editor ctx
    ctx.current_ability.is_editor_of?(ctx.instance_variable_get('@media_object').collection)
  end
  def self.is_lti_session ctx
    ctx.user_session.present? && ctx.user_session[:lti_group].present?
  end

  is_editor_or_not_lti = proc { |ctx| self.is_editor(ctx) || !self.is_lti_session(ctx) }
  is_editor_or_lti = proc { |ctx| (Avalon::Authentication::Providers.any? {|p| p[:provider] == :lti } &&self.is_editor(ctx)) || self.is_lti_session(ctx) }

  add_conditional_partial :share, :share, partial: 'share_resource', if: is_editor_or_not_lti
  add_conditional_partial :share, :embed, partial: 'embed_resource', if: is_editor_or_not_lti
  add_conditional_partial :share, :lti_url, partial: 'lti_url',  if: is_editor_or_lti

  def can_embed?
    params[:action] == 'show'
  end

  def authenticate_api!
    return head :unauthorized if !signed_in?
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

  # POST /media_objects
  def create
    # @media_object = initialize_media_object
    update_media_object
  end

  # PUT /media_objects/avalon:1.json
  def json_update
    update_media_object
  end

  def update_media_object
    begin
      collection = Admin::Collection.find(params[:collection_id])
    rescue ActiveFedora::ObjectNotFoundError
      render json: {errors: ["Collection not found for #{params[:collection_id]}"]}, status: 422
      return
    end

    @media_object.collection = collection
    @media_object.avalon_uploader = 'REST API'

    populate_from_catalog = !!params[:import_bib_record]
    if populate_from_catalog and Avalon::BibRetriever.configured?
      begin
        # Set other identifiers
        @media_object.update_attributes(media_object_parameters.slice(:other_identifier_type, :other_identifier))
        # Try to use Bib Import
        @media_object.descMetadata.populate_from_catalog!(Array(params[:fields][:bibliographic_id]).first,
                                                         Array(params[:fields][:bibliographic_id_label]).first)
      rescue
        logger.warn "Failed bib import using bibID #{Array(params[:fields][:bibliographic_id]).first}, #{Array(params[:fields][:bibliographic_id_label]).first}"
      ensure
        if !@media_object.valid?
          # Fall back to MODS as sent if Bib Import fails
          @media_object.update_attributes(media_object_parameters.slice(*@media_object.errors.keys)) if params.has_key?(:fields) and params[:fields].respond_to?(:has_key?)
        end
      end
    else
      @media_object.update_attributes(media_object_parameters) if params.has_key?(:fields) and params[:fields].respond_to?(:has_key?)
    end

    error_messages = []

    if !@media_object.valid?
      invalid_fields = @media_object.errors.keys
      required_fields = [:title, :date_issued]
      if !required_fields.any? { |f| invalid_fields.include? f }
        invalid_fields.each do |field|
          #NOTE this will erase all values for fields with multiple values
          logger.warn "Erasing field #{field} with bad value, bibID: #{Array(params[:fields][:bibliographic_id]).first}, avalon ID: #{@media_object.id}"
          @media_object.send("#{field}=", nil)
        end
      end
    end
    if !@media_object.save
      error_messages += ['Failed to create media object:']+@media_object.errors.full_messages
    elsif params[:files].respond_to?('each')
      old_ordered_master_files = @media_object.ordered_master_files.to_a.collect(&:id)
      master_files_params.each do |file_spec|
        master_file = MasterFile.new(file_spec.except(:structure, :captions, :captions_type, :files, :other_identifier))
        # master_file.media_object = @media_object
        master_file.structuralMetadata.content = file_spec[:structure] if file_spec[:structure].present?
        if file_spec[:captions].present?
          master_file.captions.content = file_spec[:captions]
          master_file.captions.mime_type = file_spec[:captions_type]
        end
        # TODO: Document this API change!
        master_file.title = file_spec[:title] if file_spec[:title].present?
        master_file.date_digitized = DateTime.parse(file_spec[:date_digitized]).to_time.utc.iso8601 if file_spec[:date_digitized].present?
        master_file.identifier += Array(file_spec[:other_identifier])
        if master_file.update_derivatives(file_spec[:files], false)
          @media_object.ordered_master_files += [master_file]
        else
          error_messages += ["Problem saving MasterFile for #{file_spec[:file_location] rescue "<unknown>"}:"]+master_file.errors.full_messages
          @media_object.destroy
          break
        end
      end

      if error_messages.empty?
        if params[:replace_master_files]
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
          @media_object.destroy
        elsif !!params[:publish]
          @media_object.publish!('REST API')
          @media_object.workflow.publish
        end
      end
    end
    if error_messages.empty?
      render json: {id: @media_object.id}, status: 200
    else
      logger.warn "update_media_object failed for #{params[:fields][:title] rescue '<unknown>'}: #{error_messages}"
      render json: {errors: error_messages}, status: 422
      @media_object.destroy
    end
  end

  def custom_edit
    if ['preview', 'structure', 'file-upload'].include? @active_step
      @masterFiles = load_master_files
    end

    if 'preview' == @active_step
      @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first
      @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.id)
      @currentStreamInfo = @currentStream.nil? ? {} : @currentStream.stream_details(@token, default_url_options[:host])

      if (not @masterFiles.empty? and @currentStream.blank?)
        @currentStream = @masterFiles.first
        flash[:notice] = "That stream was not recognized. Defaulting to the first available stream for the resource"
      end
    end

    if 'access-control' == @active_step
      @groups = @media_object.local_read_groups
      @group_leases = @media_object.governing_policies.to_a.select { |p| p.class==Lease && p.lease_type=="local" }
      @users = @media_object.read_users
      @user_leases = @media_object.governing_policies.to_a.select { |p| p.class==Lease && p.lease_type=="user" }
      @virtual_groups = @media_object.virtual_read_groups
      @virtual_leases = @media_object.governing_policies.to_a.select { |p| p.class==Lease && p.lease_type=="external" }
      @ip_groups = @media_object.ip_read_groups
      @ip_leases = @media_object.governing_policies.to_a.select { |p| p.class==Lease && p.lease_type=="ip" }
      @visibility = @media_object.visibility

      @addable_groups = Admin::Group.non_system_groups.reject { |g| @groups.include? g.name }
      @addable_courses = Course.all.reject { |c| @virtual_groups.include? c.context_id }
    end
  end

  def custom_update
    flash[:notice] = @notice
  end

  def index
    respond_to do |format|
      format.json {
        paginate json: MediaObject.all
      }
    end
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
      format.js do
        render json: @currentStreamInfo
      end
      format.json do
        render json: @media_object.to_json
      end
    end
  end

  def show_progress
    overall = { :success => 0, :error => 0 }

    result = Hash[
      @media_object.ordered_master_files.to_a.collect { |mf|
        mf_status = {
          :status => mf.status_code,
          :complete => mf.percent_complete.to_i,
          :success => mf.percent_succeeded.to_i,
          :error => mf.percent_failed.to_i,
          :operation => mf.operation,
          :message => mf.error.try(:sub,/^.+:/,'')
        }
        if mf.status_code == 'FAILED'
          mf_status[:error] = 100-mf_status[:success]
          overall[:error] += 100
        else
          overall[:success] += mf_status[:complete]
        end
        [mf.id, mf_status]
      }
    ]
    master_files_count = @media_object.master_files.to_a.size
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
    Array(params[:id]).each do |id|
      media_object = MediaObject.find(id)
      if can? :destroy, media_object
        media_object.destroy
        success_count += 1
      else
        errors += [ "#{media_object.title} (#{params[:id]}) permission denied" ]
      end
    end
    message = "#{success_count} #{'media object'.pluralize(success_count)} successfully deleted."
    message += "These objects were not deleted:</br> #{ errors.join('<br/> ') }" if errors.count > 0
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
        errors += ["#{media_object.title} (#{id}) (permission denied)."]
      else
        case status
          when 'publish'
            media_object.publish!(user_key)
            # additional save to set permalink
            media_object.save( validate: false )
            success_count += 1
          when 'unpublish'
            if can? :unpublish, media_object
              media_object.publish!(nil)
              success_count += 1
            else
              errors += ["#{media_object.title} (#{id}) (permission denied)."]
            end
        end
      end
    end
    message = "#{success_count} #{'media object'.pluralize(success_count)} successfully #{status}ed."
    message += "These objects were not #{status}ed:</br> #{ errors.join('<br/> ') }" if errors.count > 0
    redirect_to :back, flash: {notice: message.html_safe}
  end

  # Sets the published status for the object. If no argument is given then
  # it will just toggle the state.
  def tree
    @media_object = MediaObject.find(params[:id])
    authorize! :inspect, @media_object

    respond_to do |format|
      format.html {
        render 'tree', :layout => !request.xhr?
      }
      format.json {
        result = { @media_object.id => {} }
        @media_object.ordered_master_files.each do |mf|
          result[@media_object.id][mf.id] = mf.derivatives.collect(&:id)
        end
        render :json => result
      }
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
    render nothing: true
  end

  protected

  def load_master_files #(opts = {})
    @media_object.ordered_master_files.to_a #opts
  end

  def load_player_context
    return if request.format.json? and !params.has_key? :content

    if params[:part]
      index = params[:part].to_i-1
      if index < 0 or index > @media_object.ordered_master_files.to_a.size
        raise ActiveFedora::ObjectNotFoundError
      end
      params[:content] = @media_object.ordered_master_files.to_a[index]
    end

    @masterFiles = load_master_files # load_from_solr: true
    @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first
    @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.id)
    # This rescue statement seems a bit dodgy because it catches *all*
    # exceptions. It might be worth refactoring when there are some extra
    # cycles available.
    @currentStreamInfo = @currentStream.nil? ? {} : @currentStream.stream_details(@token, default_url_options[:host])
    @currentStreamInfo['t'] = view_context.parse_media_fragment(params[:t]) # add MediaFragment from params
 end

  # The goal of this method is to determine which stream to provide to the interface
  #
  # for immediate playback. Eventually this might be replaced by an AJAX call but for
  # now to update the stream you must do a full page refresh.
  #
  # If the stream is not a member of that media object or does not exist at all then
  # return a nil value that needs to be handled appropriately by the calling code
  # block
  def set_active_file(file_id = nil)
    @masterFiles ||= load_master_files #load_from_solr: true
    file_id.nil? ? nil : @masterFiles.find { |mf| mf.id == file_id }
  end

  def media_object_parameters
    # TODO: Restrist permitted params!!!
    # params.require(:fields).permit!
    # params.permit!
    ActionController::Parameters.new(Hash(params[:fields]).merge(Hash(params[:media_object]))).permit!
  end
  def master_files_params
    # TODO: Restrist permitted params!!!
    params.permit!
    params[:files]
  end
end
