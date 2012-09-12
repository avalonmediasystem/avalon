class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
	    # You need to implement the method below in your model (e.g. app/models/user.rb)
	    @user = User.find_for_cas(request.env["omniauth.auth"], current_user)

	    if @user.persisted?
	      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "CAS"
	      sign_in_and_redirect @user, :event => :authentication
	    else
	      session["devise.cas_data"] = request.env["omniauth.auth"]
	      redirect_to root_url #Have this redirect someplace better like IU CAS guest account creation page
	    end
  end
end
