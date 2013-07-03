class Admin::CollectionsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  # GET /collections
  def index
    if can? :manage, Admin::Collection
      @collections = Admin::Collection.all
    else
      @collections = Admin::Collection.where(inherited_edit_access_person_t: user_key)
    end
  end

  # GET /collections/1
  def show
  end

  # GET /collections/new
  def new
    @collection = Admin::Collection.new
  end

  # GET /collections/1/edit
  def edit
  end

  # POST /collections
  def create
    @collection = Admin::Collection.new(params[:collection])
    @collection.managers = [user_key]

    respond_to do |format|
      if @collection.save
        redirect_to @collection, notice: 'Collection was successfully created.'
      else
        render action: "new"
      end
    end
  end

  # PUT /collections/1
  def update
    @collection = Admin::Collection.find(params[:id])
    bad_params = params.select {|param| cannot? "update_#{param.key}".to_sym, @collection}

    respond_to do |format|
      if !bad_params.empty?
        flash[:notice] = "You are not allowed to update " + bad_params.keys.join(",") + 'field'.plurlalize(bad_params.size)
        render action: "edit"
      elsif @collection.update_attributes(params[:collection])
        redirect_to @collection, notice: 'Collection was successfully updated.'
      else
        render action: "edit"
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
