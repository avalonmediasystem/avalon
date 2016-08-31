class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  layout 'avalon'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :render_bookmarks_control?

  around_action :handle_api_request, if: proc{|c| request.format.json?}

  def handle_api_request
    if request.headers['Avalon-Api-Key'].present?
      token = request.headers['Avalon-Api-Key']
      #verify token (and IP)
      apiauth = Avalon::Authentication::Config.find {|p| p[:id] == :api }
      apiauth ||= { tokens: {} }
      if apiauth[:tokens].include? token
        token_creds = apiauth[:tokens][token]
  #        user = User.find_by_api(token_creds[:username], token_creds[:email])
        user = User.find_by_username(token_creds[:username]) ||
               User.find_by_email(token_creds[:email]) ||
               User.create(:username => token_creds[:username], :email => token_creds[:email])

        sign_in user, event: :authentication
        user_session[:json_api_login] = true
        user_session[:full_login] = false
      else
        render json: {errors: ["Permission denied."]}, status: 403
        return
      end
    end
    yield
    if user_session.present? && !!user_session[:json_api_login]
      sign_out current_user
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    if current_user
      redirect_to root_path, flash: { notice: 'You are not authorized to perform this action.' }
    else
      session[:previous_url] = request.fullpath unless request.xhr?
      redirect_to new_user_session_path, flash: { notice: 'You are not authorized to perform this action. Try logging in.' }
    end
  end

  rescue_from ActiveFedora::ObjectNotFoundError do |exception|
    if request.format == :json
      render json: {errors: ["#{params[:id]} not found"]}, status: 404
    else
      render '/errors/unknown_pid', status: 404
    end
  end
end
