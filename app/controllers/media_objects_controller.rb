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

require 'avalon/controller/controller_behavior'

class MediaObjectsController < ApplicationController 
  include Avalon::Workflow::WorkflowControllerBehavior
  include Avalon::Controller::ControllerBehavior

  before_filter :enforce_access_controls
  before_filter :inject_workflow_steps, only: [:edit, :update]
  before_filter :load_player_context, only: [:show, :show_progress, :remove]

  layout 'avalon'

  # Catch exceptions when you try to reference an object that doesn't exist.
  # Attempt to resolve it to a close match if one exists and offer a link to
  # the show page for that item. Otherwise ... nothing!
  rescue_from ActiveFedora::ObjectNotFoundError do |exception|
    render '/errors/unknown_pid', status: 404
  end
  
  def new
    logger.debug "<< NEW >>"
    @mediaobject = MediaObjectsController.initialize_media_object(user_key)
    @mediaobject.workflow.origin = 'web'
    @mediaobject.save(:validate => false)

    redirect_to edit_media_object_path(@mediaobject)
  end

  def custom_edit
    if ['preview', 'structure', 'file-upload'].include? @active_step
      @masterFiles = load_master_files
    end

    if 'preview' == @active_step 
      @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first
      @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.mediapackage_id)
      @currentStreamInfo = @currentStream.nil? ? {} : @currentStream.stream_details(@token,request.host)

      if (not @masterFiles.empty? and @currentStream.blank?)
        @currentStream = @masterFiles.first
        flash[:notice] = "That stream was not recognized. Defaulting to the first available stream for the resource"
      end
    end

    if 'access-control' == @active_step 
      @group_exceptions = []
      if @mediaobject.access == "limited"
        # When access is limited, group_exceptions content is stored in read_groups
        @mediaobject.read_groups.each { |g| @group_exceptions << Admin::Group.find(g).name if Admin::Group.exists?(g)}
        @user_exceptions = @mediaobject.read_users 
       else
        @mediaobject.group_exceptions.each { |g| @group_exceptions << Admin::Group.find(g).name if Admin::Group.exists?(g)}
        @user_exceptions = @mediaobject.user_exceptions 
      end

      @addable_groups = Admin::Group.non_system_groups.reject { |g| @group_exceptions.include? g.name }
    end
  end

  def custom_update
    flash[:notice] = @notice
  end

  def show
    respond_to do |format|
      # The flash notice is only set if you are returning HTML since it makes no
      # sense in an AJAX context (yet)
      format.html do
       	if (not @masterFiles.empty? and @currentStream.blank?)
          @currentStream = @masterFiles.first
          flash[:notice] = "That stream was not recognized. Defaulting to the first available stream for the resource"
        end
        render
      end
      format.json do
        render :json => @currentStreamInfo 
      end
    end
  end

  def show_progress
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
    overall.each { |k,v| overall[k] = [0,[100,v.to_f/@masterFiles.length.to_f].min].max.round }

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

  # Deletes a media object from the system. This needs to be somewhat robust so that
  # you can't delete an object if you do not have permission, if it does not exist, or
  # (most likely) if the 'Yes' button was accidentally submitted twice
  def destroy
    logger.debug "<< DESTROY >>"
    logger.debug "<< Media object => #{params[:id]} >>"
    logger.debug "<< Exists? #{MediaObject.exists? params[:id]} >>"
    unless params[:id].nil? or (not MediaObject.exists?(params[:id]))
      logger.debug "<< Removing PID from system >>"
      media = MediaObject.find(params[:id])

      # attempt to stop the matterhorn processing job
      media.parts.each(&:destroy)
      
      flash[:notice] = "#{media.title} (#{params[:id]}) has been successfuly deleted"
      media.delete
    end
    logger.debug "<< Exists? #{MediaObject.exists? params[:id]} >>"
    redirect_to root_path
  end


  # Sets the published status for the object. If no argument is given then
  # it will just toggle the state.
  def update_status
    media_object = MediaObject.find(params[:id])
    authorize! :manage, media_object
    
    logger.debug "<< Status flag is #{params[:status]} >>"
    case params[:status]
      when 'publish'
        logger.debug "<< Setting user key to #{user_key} >>"
        media_object.publish!(user_key)
      when 'unpublish'
        logger.debug "<< Setting user key to nil >>"
        media_object.publish!(nil)
      when nil
        logger.debug "<< Toggling user key >>"
        new_state = media_object.published? ? nil : user_key
        media_object.publish!(new_state)        
    end

    redirect_to :back
  end

  # Sets the published status for the object. If no argument is given then
  # it will just toggle the state.
  def update_visibility
    media_object = MediaObject.find(params[:id])
    authorize! :manage, media_object
    
    logger.debug "<< Visibility flag is #{params[:status]} >>"
    case params[:status]
      when 'show'
        logger.debug "<< Setting hidden to false >>"
        media_object.hidden = false
      when 'hide'
        logger.debug "<< Setting hidden to true >>"
        media_object.hidden = true
      when nil
        logger.debug "<< Toggling visibility >>"
        new_state = media_object.hidden? ? false : true
        media_object.hidden = new_state        
    end

    media_object.save
    redirect_to :back
  end
  
  def self.initialize_media_object( user_key )
    mediaobject = MediaObject.new( avalon_uploader: user_key )
    set_default_item_permissions( mediaobject, user_key )

    mediaobject
  end

  def matterhorn_service_config
    respond_to do |format|
      format.any(:xml, :json) { render request.format.to_sym => Avalon.matterhorn_config(request.host) }
    end
  end

  protected

  def load_master_files
    logger.debug "<< LOAD MASTER FILES >>"
    logger.debug "<< #{@mediaobject.parts_with_order} >>"

    @mediaobject.parts_with_order
  end

  def load_player_context
    @mediaobject = MediaObject.find(params[:id])
    logger.debug "<< Preparing media object #{@mediaobject} >>"

    @masterFiles = load_master_files
    @currentStream = params[:content] ? set_active_file(params[:content]) : @masterFiles.first
    @token = @currentStream.nil? ? "" : StreamToken.find_or_create_session_token(session, @currentStream.mediapackage_id)
    # This rescue statement seems a bit dodgy because it catches *all*
    # exceptions. It might be worth refactoring when there are some extra
    # cycles available.
    @currentStreamInfo = @currentStream.nil? ? {} : @currentStream.stream_details(@token,request.host)
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
