module ControllerMacros
  def login_archivist
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in FactoryGirl.create(:archivist) # Using factory girl as an example
  end

	def login_user
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in FactoryGirl.create(:user)
  end
end

