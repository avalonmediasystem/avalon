class ObjectController < ApplicationController
  def show
    obj = ActiveFedora::Base.find('dc_identifier_tesim' => params[:id])
    obj ||= ActiveFedora::Base.find(params[:id], cast: true) rescue ActiveFedora::ObjectNotFoundError
    params.delete(:controller)
    params.delete(:action)
    if obj.blank?
      redirect_to root_path
    else
      redirect_to polymorphic_path(obj, params)
    end
  end
end
