class Admin::CollectionsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  # GET /collections
  def index
    if can? :manage, Admin::Collection
      @collections = Admin::Collection.all
    else
      @collections = Admin::Collection.where(inheritable_edit_access_person_t: user_key)
    end
  end

  # GET /collections/1
  def show
      @group_exceptions = []
      if @collection.defaultRights.access == "limited"
        # When access is limited, group_exceptions content is stored in read_groups
        @collection.defaultRights.read_groups.each { |g| @group_exceptions << Admin::Group.find(g).name if Admin::Group.exists?(g)}
        @user_exceptions = @collection.defaultRights.read_users 
       else
        @collection.defaultRights.group_exceptions.each { |g| @group_exceptions << Admin::Group.find(g).name if Admin::Group.exists?(g)}
        @user_exceptions = @collection.defaultRights.user_exceptions 
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
    @collection = Admin::Collection.create(params[:admin_collection])
    
    respond_to do |format|
      format.js do
        render json: modal_form_response(@collection)
      end
    end
  end

  # PUT /collections/1
  def update
    @collection = Admin::Collection.find(params[:id])
    bad_params = params[:admin_collection].select{|name| cannot?("update_#{name}".to_sym, @collection) }
    error_message = 'You are not allowed to update ' + bad_params.keys.join(',') + 'field'.pluralize(bad_params.size) if bad_params.present?

      # Limited access stuff
      if params[:delete_group].present?
        groups = @collection.defaultRights.read_groups
        groups.delete params[:delete_group]
        @collection.defaultRights.read_groups = groups
      end 
      if params[:delete_user].present?
        users = @collection.defaultRights.read_users
        users.delete params[:delete_user]
        @collection.defaultRights.read_users = users
      end 

      if params[:commit] == "Add Group"
        groups = @collection.defaultRights.group_exceptions
        groups << params[:new_group] unless params[:new_group].blank?
        @collection.defaultRights.group_exceptions = groups
      elsif params[:commit] == "Add User"
        users = @collection.defaultRights.user_exceptions
        users << params[:new_user] unless params[:new_user].blank?
        @collection.defaultRights.user_exceptions = users
        puts "EXCEPTIONS #{MediaObject.find(@collection.defaultRights.pid).group_exceptions.inspect}"
      end

      @collection.defaultRights.access = params[:access] unless params[:access].blank? 

      logger.debug "<< Hidden = #{params[:hidden]} >>"
      @collection.defaultRights.hidden = params[:hidden] == "1"

      @collection.save
      logger.debug "<< Groups : #{@collection.defaultRights.read_groups} >>"
      logger.debug "<< Users : #{@collection.defaultRights.read_users} >>"


    respond_to do |format|
      format.html { redirect_to @collection }
      format.js do 
        if bad_params.present?
          @collection.attributes =  params[:admin_collection].reject{|key| key.in?(bad_params)}
          render json: modal_form_response(@collection, errors: { base: error_message })
        else
          @collection.update_attributes params[:admin_collection]
          render json: modal_form_response(@collection)
        end
      end
    end

  end

  # DELETE /collections/1
  def destroy
    @collection = Admin::Collection.find(params[:id])
    @collection.destroy
    redirect_to collections_url
  end
end
