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
    error_message = 'You are not allowed to update ' + bad_params.keys.join(',') + 'field'.plurlalize(bad_params.size) if bad_params.present?

    respond_to do |format|
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
