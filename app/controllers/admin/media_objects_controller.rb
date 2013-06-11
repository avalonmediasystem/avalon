class Admin::MediaObjectsController < ApplicationController
  before_filter :authenticate_user!

  def autocomplete
    authorize! :manage, MediaObject

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

    def filter_for_media_objects(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << 'has_model_s:"info:fedora/afmodel:MediaObject"'
    end
end