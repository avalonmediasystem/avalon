class Admin::CollectionsController < ApplicationController
  before_filter :authenticate_user!, :set_parent_name!
  load_and_authorize_resource
  before_filter :load_and_authorize_nested_models, only: [:create, :update]
  before_filter :load_and_authorize_unit, only: [:create, :update]
  respond_to :html
  responders :flash


  def index
    @collections = Collection.all
  end

  def create
    @collection.unit = @unit
    if @collection.save
      after_save
      respond_with @collection do |format|
        format.html{ redirect_to [@parent_name, @collection] }
      end
    else
      render 'new'
    end
  end

  def update
    @oldunit = @collection.unit
    if @collection.update_attributes params[:collection]
      @collection.unit = @unit
      @collection.save
      @unit.collections += [@collection]
      @unit.save( validate:false )
      @oldunit.collections -= [@collection]
      @oldunit.save(validate: false)
      respond_with @collection do |format|
        format.html{ redirect_to [@parent_name, @collection] }
      end
    else
      render 'edit'
    end
  end

  def destroy
    @collection.destroy
    redirect_to [@parent_name, Collection]
  end

  def autocomplete
    solr_search_params_logic  = {}
    filter_for_collection_objects(solr_search_params_logic)
    collection_response = ActiveFedora::SolrService.query("name_t:#{params[:q]}*", solr_search_params_logic)
    collections = collection_response.map{|m| MediaObject.find( m['id'] ) }

    collections_as_json = collections.map do |collection|
      Select2::Autocomplete.as_json(collection.id, collection.name, collection.thumbnail_urls(4) )
    end

    render json: { media_objects: media_objects_as_json }
  end

  private

    def after_load
      unit_id = params[:collection].delete(:unit_id)
      if unit_id.present?
        @unit = Unit.find(unit_id)
        authorize! :manage, @unit
      else
        @unit = nil
      end
      
      @collection.managers =  find_managers!( params )
    end

    def after_save
      if @unit.present?
        @unit.reload
        @unit.collection = @collection
        @unit.save( validate: false )
      end
    end

    def filter_for_collection_objects(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << 'has_model_s:"info:fedora/afmodel:Collection"'
    end

end
