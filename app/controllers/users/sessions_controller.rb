class Users::SessionsController < Devise::SessionsController
  def new
    if Avalon::Authentication::Providers.length == 1
      redirect_to user_omniauth_authorize_path(Avalon::Authentication::Providers.first[:provider])
    else
      super
    end
  end

  def destroy
    StreamToken.logout! session
    super
  end
end
