class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def passthru
    begin
      render "modules/#{params[:provider]}_auth_form"
    rescue ActionView::MissingTemplate
      super
    end
  end

  def after_omniauth_failure_path_for(scope)
    new_user_session_path(scope)
  end

  def cas
    find_user('CAS')
  end

  def identity
    find_user('Identity')
  end

  def ldap
    find_user('LDAP')
  end

  def find_user(auth_type)
    find_method = "find_for_#{auth_type.downcase}".to_sym
    logger.debug "#{auth_type} :: #{current_user.inspect}"
  	@user = User.send(find_method,request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => auth_type
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.#{auth_type.downcase}_data"] = request.env["omniauth.auth"]
      redirect_to root_url #Have this redirect someplace better like IU CAS guest account creation page
    end
  end
  protected :find_user
end
