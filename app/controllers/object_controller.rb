class ObjectController < ApplicationController
  def show
    obj = ActiveFedora::Base.find('dc_identifier_tesim' => params[:id])
    obj ||= ActiveFedora::Base.find(params[:id], cast: true) rescue ActiveFedora::ObjectNotFoundError
    if obj.blank?
      redirect_to root_path
    else
      redirect_to polymorphic_path(obj, params.except(:controller, :action))
    end
  end
end
