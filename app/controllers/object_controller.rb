class ObjectController < ApplicationController
  def show
    obj = ActiveFedora::Base.find('dc_identifier_tesim' => params[:id])
    obj ||= ActiveFedora::Base.find(params[:id], cast: true) rescue ActiveFedora::ObjectNotFoundError
    if obj.blank?
      redirect_to root_path
    else
      if params[:urlappend]
        url = URI.join(polymorphic_url(obj)+'/', params[:urlappend].sub(/^[\/]/,''))
      else
        url = URI(polymorphic_url(obj))
      end

      newparams = params.except(:controller, :action, :id, :urlappend)
      url.query = newparams.to_query if newparams.present?
      redirect_to url.to_s
    end
  end

  def autocomplete
    model = Module.const_get(params[:t].to_s.classify)
    query = params[:q]
    render json: model.send(:autocomplete, query)
  end
end
