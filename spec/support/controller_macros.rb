module ControllerMacros
  def login_as_archivist
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in FactoryGirl.create(:cataloger) # Using factory girl as an example
  end

	def login_as_user
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in FactoryGirl.create(:student)
  end
end

