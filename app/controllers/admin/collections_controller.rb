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
    @group_exceptions = []
    if @collection.default_access == "limited"
      # When access is limited, group_exceptions content is stored in read_groups
      @collection.default_read_groups.each { |g| @group_exceptions << Admin::Group.find(g).name if Admin::Group.exists?(g)}
      @user_exceptions = @collection.default_read_users 
     else
      @collection.default_group_exceptions.each { |g| @group_exceptions << Admin::Group.find(g).name if Admin::Group.exists?(g)}
      @user_exceptions = @collection.default_user_exceptions 
    end

    @addable_groups = Admin::Group.non_system_groups.reject { |g| @group_exceptions.include? g.name }
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
    if @collection.save

      User.where(email: [RoleControls.users('administrator')].flatten).each do |admin_user|
        NotificationsMailer.delay.new_collection( 
          creator_id: current_user.id, 
          collection_id: @collection.id, 
          user_id: admin_user.id, 
          subject: "New collection: #{@collection.name}",
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

    ["manager", "editor", "depositor"].each do |title|
      attribute_accessor_name = "add_#{title}"
      if params[attribute_accessor_name].present? && can?("update_#{title.pluralize}".to_sym, @collection)
        if params["new_#{title}"].present?
          begin
            @collection.send attribute_accessor_name.to_sym, params["new_#{title}"]
          rescue ArgumentError => e
            flash[:notice] = e.message
          end
        else
          flash[:notice] = "#{title.titleize} can't be blank."
        end
      end
    end

    # If one of the "x" (remove manager, editor, depositor) buttons has been clicked
    ["manager", "editor", "depositor"].each do |title|
      attribute_accessor_name = "remove_#{title}"
      if params[attribute_accessor_name].present? && can?("update_#{title.pluralize}".to_sym, @collection)
        @collection.send attribute_accessor_name.to_sym, params[attribute_accessor_name]
      end
    end

    # If Save Access Setting button or Add/Remove User/Group button has been clicked
    if can?(:update_access_control, @collection)
      # Limited access stuff
      if params[:delete_group].present?
        groups = @collection.default_read_groups
        groups.delete params[:delete_group]
        @collection.default_read_groups = groups
      end 
      if params[:delete_user].present?
        users = @collection.default_read_users
        users.delete params[:delete_user]
        @collection.default_read_users = users
      end 

      if params[:commit] == "Add Group"
        groups = @collection.default_group_exceptions
        groups << params[:new_group] unless params[:new_group].blank?
        @collection.default_group_exceptions = groups
      elsif params[:commit] == "Add User"
        users = @collection.default_user_exceptions
        users << params[:new_user] unless params[:new_user].blank?
        @collection.default_user_exceptions = users
      end

      @collection.default_access = params[:access] unless params[:access].blank? 

      @collection.default_hidden = params[:hidden] == "1"
    end

    @collection.save

    if @collection.managers.count == 0
      flash[:notice] = "Collection requires at least 1 manager" 
    end

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
    if @source_collection.media_objects.length > 0
      @target_collection = Admin::Collection.find(params[:target_collection_id])
      Admin::Collection.reassign_media_objects( @source_collection.media_objects, @source_collection, @target_collection )
      target_path = admin_collection_path(@target_collection)
    end
    if @source_collection.media_objects.length == 0
      @source_collection.destroy
      redirect_to target_path
    else
      flash[:notice] = "Something went wrong. #{@source_collection.name} is not empty."
      redirect_to admin_collection_path(@source_collection)
    end
  end

end
