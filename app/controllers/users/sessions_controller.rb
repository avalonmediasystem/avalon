class Users::SessionsController < Devise::SessionsController
	def new
		if Hydrant::Authentication::Providers.length == 1
			redirect_to user_omniauth_authorize_path(Hydrant::Authentication::Providers.first[:provider])
		else
			super
		end
	end
end
