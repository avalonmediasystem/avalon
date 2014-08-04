# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
  include Hydra::AccessControlsEnforcement

#  before_filter :enforce_access_controls
  before_filter :inject_workflow_steps, only: [:edit, :update]
  before_filter :load_player_context, only: [:show, :show_progress, :remove]

  # Catch exceptions when you try to reference an object that doesn't exist.
  # Attempt to resolve it to a close match if one exists and offer a link to
  # the show page for that item. Otherwise ... nothing!
  rescue_from ActiveFedora::ObjectNotFoundError do |exception|
    render '/errors/unknown_pid', status: 404
  end
 
  def new
    collection = Admin::Collection.find(params[:collection_id])
    authorize! :read, collection

    @mediaobject = MediaObjectsController.initialize_media_object(user_key)
    @mediaobject.workflow.origin = 'web'
    @mediaobject.collection = collection
    @mediaobject.save(:validate => false)

    redirect_to edit_media_object_path(@mediaobject)
  end

  def custom_edit
    authorize! :update, @mediaobject
    if ['preview', 'structure', 'file-upload'].include? @active_step
      @masterFiles = load_master_files
    end

    if 'preview' == @active_step 
      @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first
      @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.mediapackage_id)
      @currentStreamInfo = @currentStream.nil? ? {} : @currentStream.stream_details(@token, default_url_options[:host])

      if (not @masterFiles.empty? and @currentStream.blank?)
        @currentStream = @masterFiles.first
        flash[:notice] = "That stream was not recognized. Defaulting to the first available stream for the resource"
      end
    end

    if 'access-control' == @active_step 
      @groups = @mediaobject.local_read_groups
      @users = @mediaobject.read_users
      @virtual_groups = @mediaobject.virtual_read_groups
      @visibility = @mediaobject.visibility

      @addable_groups = Admin::Group.non_system_groups.reject { |g| @groups.include? g.name }
      @addable_courses = Course.all.reject { |c| @virtual_groups.include? c.context_id }
    end
  end

  def custom_update
    authorize! :update, @mediaobject
    flash[:notice] = @notice
  end

  def show
    authorize! :read, @mediaobject
    respond_to do |format|
      format.html do
	if (not @masterFiles.empty? and @currentStream.blank?) then
          redirect_to media_object_path(@mediaobject.pid), flash: { notice: 'That stream was not recognized. Defaulting to the first available stream for the resource' }
        else 
          render
        end
      end
      format.json do
        render :json => @currentStreamInfo 
      end
    end
  end

  def show_progress
    authorize! :read, @mediaobject
    overall = { :success => 0, :error => 0 }

    result = Hash[
      @masterFiles.collect { |mf| 
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
        [mf.pid, mf_status]
      }
    ]
    overall.each { |k,v| overall[k] = [0,[100,v.to_f/@masterFiles.length.to_f].min].max.floor }

    if overall[:success]+overall[:error] > 100
      overall[:error] = 100-overall[:success]
    end

    result['overall'] = overall
    respond_to do |format|
      format.any(:xml, :json) { render request.format.to_sym => result }
    end
  end

  # This sets up the delete view which is an item preview with the ability
  # to take the item out of the system for good (by POSTing to the destroy
  # action)
  def remove 
    #@previous_view = media_object_path(@mediaobject)
  end

  def bulk_delete
    message = ""
    params[:id].each do |id|
      media_object = MediaObject.find(params[:id])
      authorize! :destroy, media_object
      message += "#{media_object.title} (#{params[:id]}) has been successfuly deleted"
      media_object.destroy
    end
    redirect_to root_path, flash: { notice: message }
  end

  def destroy
    media_object = MediaObject.find(params[:id])
    authorize! :destroy, media_object
    message = "#{media_object.title} (#{params[:id]}) has been successfuly deleted"
    media_object.destroy
    redirect_to root_path, flash: { notice: message }
  end

  # Sets the published status for the object. If no argument is given then
  # it will just toggle the state.
  def update_status
    media_object = MediaObject.find(params[:id])
    authorize! :update, media_object
    
    case params[:status]
      when 'publish'
        media_object.publish!(user_key)
      when 'unpublish'
        media_object.publish!(nil) if can?(:unpublish, media_object)   
    end

    # additional save to set permalink
    media_object.save( validate: false )
    
    redirect_to :back
  end

  # Sets the published status for the object. If no argument is given then
  # it will just toggle the state.
  def tree
    @mediaobject = MediaObject.find(params[:id])
    authorize! :inspect, @mediaobject

    respond_to do |format|
      format.html { 
        render 'tree', :layout => !request.xhr?
      }
      format.json { 
        result = { @mediaobject.pid => {} }
        @mediaobject.parts_with_order.each do |mf|
          result[@mediaobject.pid][mf.pid] = mf.derivatives.collect(&:pid)
        end
        render :json => result 
      }
    end
  end

  def self.initialize_media_object( user_key )
    mediaobject = MediaObject.new( avalon_uploader: user_key )

    mediaobject
  end

  def build_context
    params.merge!({mediaobject: model_object, user: user_key, ability: current_ability})
  end

  protected

  def load_master_files
    @mediaobject.parts_with_order
  end

  def load_player_context
    @mediaobject = MediaObject.find(params[:id])

    if params[:part]
      index = params[:part].to_i-1
      if index < 0 or index > @mediaobject.section_pid.length
        raise ActiveFedora::ObjectNotFoundError
      end
      params[:content] = @mediaobject.section_pid[index]
    end
    @masterFiles = load_master_files
    @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first
    @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.mediapackage_id)
    # This rescue statement seems a bit dodgy because it catches *all*
    # exceptions. It might be worth refactoring when there are some extra
    # cycles available.
    @currentStreamInfo = @currentStream.nil? ? {} : @currentStream.stream_details(@token, default_url_options[:host])
 end

  # The goal of this method is to determine which stream to provide to the interface
  #
  # for immediate playback. Eventually this might be replaced by an AJAX call but for
  # now to update the stream you must do a full page refresh.
  # 
  # If the stream is not a member of that media object or does not exist at all then
  # return a nil value that needs to be handled appropriately by the calling code
  # block
  def set_active_file(file_pid = nil)
    unless (@mediaobject.parts.blank? or file_pid.blank?)
      @mediaobject.parts.each do |part|
        return part if part.pid == file_pid
      end
    end

    # If you haven't dropped out by this point return an empty item
    nil
  end 
end
