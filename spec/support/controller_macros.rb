module ControllerMacros
  def login_as_archivist
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in FactoryGirl.create(:cataloger) # Using factory girl as an example
  end

  def login_as(role = 'student')
    puts "Role => #{role}"

    @request.env["devise.mapping"] = Devise.mappings[role]
    user = FactoryGirl.create(role)
    
    logger.debug "<< USER INFORMATION >>"
    logger.debug user
    
    sign_in user
  end
end

