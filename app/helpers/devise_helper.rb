module DeviseHelper
  def devise_error_messages!
    logger.debug("<< #{resource.errors.full_messages} >>")
    return "" if resource.errors.empty?
    
    flash[:error] = I18n.t("errors.messages.not_saved",
      count: resource.errors.count,
      resource: resource.class.model_name.human.downcase
    )    
  end
end