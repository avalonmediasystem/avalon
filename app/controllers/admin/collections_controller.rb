class Admin::CollectionsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource except: :remove
  respond_to :html
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

    respond_to do |format|
      format.js do
        render json: modal_form_response(@collection, redirect_location: admin_collection_path(@collection))
      end
    end
  end

  # PUT /collections/1
  def update
    @collection = Admin::Collection.find(params[:id])

    # If one of the Add (manager, editor, depositor) buttons has been clicked
    ["manager", "editor", "depositor"].each do |title|
      if params["add_#{title}".to_sym].present? && can?("update_#{title}s".to_sym, @collection)
        @collection.send "add_#{title}".to_sym, params["new_#{title}".to_sym]
      end
    end

    # If one of the "x" (remove manager, editor, depositor) buttons has been clicked
    ["manager", "editor", "depositor"].each do |title|
      sym = "remove_#{title}".to_sym
      if params[sym].present? && can?("update_#{title}s".to_sym, @collection)
        @collection.send sym, params[sym]
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
        logger.debug "<< DELETE USER #{users} >>"
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

      logger.debug "<< Hidden = #{params[:hidden]} >>"
      @collection.default_hidden = params[:hidden] == "1"

      logger.debug "<< Groups : #{@collection.default_read_groups} >>"
      logger.debug "<< Users : #{@collection.default_read_users} >>"
    end

    @collection.save

        if @collection.errors.any?
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
    @media_objects = MediaObject.find(params[:media_objects_ids])
    @collection = Collection.find(params[:collection_id])
    Admin::Collection.reassign_media_objects( @media_objects, @collection)
    redirect_to collections_url
  end

end
