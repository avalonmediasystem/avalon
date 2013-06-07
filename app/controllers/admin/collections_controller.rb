class Admin::CollectionsController < ApplicationController
  before_filter :authenticate_user!, :set_parent_name!
  load_and_authorize_resource
  before_filter :load_and_authorize_nested_models, only: [:create, :update]
  respond_to :html
  responders :flash


  def index
    @collections = Collection.all
  end

  def create
    if @collection.save
      respond_with @collection do |format|
        format.html{ redirect_to [@parent_name, @collection] }
      end
    else
      render 'new'
    end
  end

  def autocomplete
    solr_search_params_logic  = {}
    filter_for_media_objects(solr_search_params_logic)
    media_object_response = ActiveFedora::SolrService.query("title_t:#{params[:q]}*", solr_search_params_logic)
    media_objects = media_object_response.map{|m| MediaObject.find( m['id'] ) }

    media_objects_as_json = media_objects.map do |media_object|
      Select2::Autocomplete.as_json(media_object.pid, media_object.title, { thumbnail_url: media_object.thumbnail_url })
    end

    render json: { media_objects: media_objects_as_json }
  end

  private
    
    def set_parent_name!
      @parent_name =  params[:controller].to_s.split('/')[-2..-2].try :first
    end

    def filter_for_media_objects(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << 'has_model_s:"info:fedora/afmodel:MediaObject"'
    end
end