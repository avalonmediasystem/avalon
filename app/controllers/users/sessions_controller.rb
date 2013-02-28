class Users::SessionsController < Devise::SessionsController
	def new
		if Avalon::Authentication::Providers.length == 1
			redirect_to user_omniauth_authorize_path(Avalon::Authentication::Providers.first[:provider])
		else
			super
		end
	end


        def destroy
          session_key = session[:session_id]
          flash[:notice] = "You have been logged out of Avalon"
          reset_session
          redirect_to root_url
        end
end
