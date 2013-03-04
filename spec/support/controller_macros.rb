module ControllerMacros
  def login_as(role = 'student')
    @request.env["devise.mapping"] = Devise.mappings[role]
    user = FactoryGirl.create(role)
    
    logger.debug "<< USER INFORMATION >>"
    logger.debug user
    
    sign_in user
  end
end

