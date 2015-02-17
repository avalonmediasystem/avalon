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

class Admin::CollectionsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource except: [:remove, :show]
  respond_to :html
  
  # Catching a global exception seems like a bad idea here
  rescue_from Exception do |e|
    if e.message == "UserIsEditor"
      flash[:notice] = "User #{params[:new_depositor]} needs to be removed from manager or editor role first"
      redirect_to @collection
    else 
      raise e
    end
  end

  # GET /collections
  def index
    @collections = get_user_collections
  end

  # GET /collections/1
  def show
    @collection = Admin::Collection.find(params[:id])
    redirect_to admin_collections_path unless can? :read, @collection
    @groups = @collection.default_local_read_groups
    @users = @collection.default_read_users
    @virtual_groups = @collection.default_virtual_read_groups
    @visibility = @collection.default_visibility

    @addable_groups = Admin::Group.non_system_groups.reject { |g| @groups.include? g.name }
    @addable_courses = Course.all.reject { |c| @virtual_groups.include? c.context_id }
  end

  # GET /collections/new
  def new
    @collection = Admin::Collection.new
    respond_to do |format|
      format.js   { render json: modal_form_response(@collection) }
      format.html { render 'new' }
    end
  end

  # GET /collections/1/edit
  def edit
    @collection = Admin::Collection.find(params[:id])
    respond_to do |format|
      format.js   { render json: modal_form_response(@collection) }
    end
  end
 
  # POST /collections
  def create
    @collection = Admin::Collection.create(params[:admin_collection].merge(managers: [user_key]))
    if @collection.persisted?
      User.where(username: [RoleControls.users('administrator')].flatten).each do |admin_user|
        NotificationsMailer.delay.new_collection( 
          creator_id: current_user.id, 
          collection_id: @collection.id, 
          user_id: admin_user.id, 
          subject: "New collection: #{@collection.name}"
        )
      end

      render json: modal_form_response(@collection, redirect_location: admin_collection_path(@collection))
    else
      render json: modal_form_response(@collection)
    end
  end
  
  # PUT /collections/1
  def update
    @collection = Admin::Collection.find(params[:id])
    if params[:admin_collection].present? && params[:admin_collection][:name].present?
      if params[:admin_collection][:name] != @collection.name && can?('update_name', @collection)
        @old_name = @collection.name
        @collection.name = params[:admin_collection][:name]
        if @collection.save
          User.where(username: [RoleControls.users('administrator')].flatten).each do |admin_user|
            NotificationsMailer.delay.update_collection( 
              updater_id: current_user.id, 
              collection_id: @collection.id, 
              user_id: admin_user.id,
              old_name: @old_name,
              subject: "Notification: collection #{@old_name} changed to #{@collection.name}"
            )
          end
        end
      end
    end

    ["manager", "editor", "depositor"].each do |title|
      if params["submit_add_#{title}"].present? 
        if params["add_#{title}"].present? && can?("update_#{title.pluralize}".to_sym, @collection)
          begin
            @collection.send "add_#{title}".to_sym, params["add_#{title}"].strip
          rescue ArgumentError => e
            flash[:notice] = e.message
          end
        else
          flash[:notice] = "#{title.titleize} can't be blank."
        end
      end
      
      remove_access = "remove_#{title}"
      if params[remove_access].present? && can?("update_#{title.pluralize}".to_sym, @collection)
          @collection.send remove_access.to_sym, params[remove_access]
      end
    end

    # If Save Access Setting button or Add/Remove User/Group button has been clicked
    if can?(:update_access_control, @collection)
      ["group", "class", "user"].each do |title|
        if params["submit_add_#{title}"].present?
          if params["add_#{title}"].present?
            if ["group", "class"].include? title
              @collection.default_read_groups += [params["add_#{title}"].strip]
            else
              @collection.default_read_users += [params["add_#{title}"].strip]
            end
          else
            flash[:notice] = "#{title.titleize} can't be blank."
          end
        end
        
        if params["remove_#{title}"].present?
          if ["group", "class"].include? title
            @collection.default_read_groups -= [params["remove_#{title}"]]
          else
            @collection.default_read_users -= [params["remove_#{title}"]]
          end
        end
    end

      @collection.default_visibility = params[:visibility] unless params[:visibility].blank? 

      @collection.default_hidden = params[:hidden] == "1"
    end
    
    @collection.save
    respond_to do |format|
      format.html { redirect_to @collection }
      format.js do 
        @collection.update_attributes params[:admin_collection]
        render json: modal_form_response(@collection)
      end
    end
  end

  # GET /collections/1/reassign
  def remove
    @collection = Admin::Collection.find(params[:id])
    @objects    = @collection.media_objects
    @candidates = get_user_collections.reject { |c| c == @collection }
  end

  # DELETE /collections/1
  def destroy
    @source_collection = Admin::Collection.find(params[:id])
    target_path = admin_collections_path
    if @source_collection.media_objects.count > 0
      @target_collection = Admin::Collection.find(params[:target_collection_id])
      Admin::Collection.reassign_media_objects( @source_collection.media_objects, @source_collection, @target_collection )
      target_path = admin_collection_path(@target_collection)
    end
    if @source_collection.media_objects.count == 0
      @source_collection.destroy
      redirect_to target_path
    else
      flash[:notice] = "Something went wrong. #{@source_collection.name} is not empty."
      redirect_to admin_collection_path(@source_collection)
    end
  end
end
