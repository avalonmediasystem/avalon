# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

class ApplicationController < ActionController::Base
  before_action :store_location, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  # To deal with a load order issue breaking persona impersonate
  include Samvera::Persona::BecomesBehavior
  layout 'avalon'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, unless: proc{|c| request.headers['Avalon-Api-Key'].present? }

  helper_method :render_bookmarks_control?

  around_action :handle_api_request, if: proc{|c| request.format.json? || request.format.atom? }
  before_action :rewrite_v4_ids, if: proc{|c| request.method_symbol == :get && [params[:id], params[:content]].compact.any? { |i| i =~ /^[a-z]+:[0-9]+$/}}
  before_action :set_no_cache_headers, if: proc{|c| request.xhr? }
  prepend_before_action :remove_zero_width_chars
  skip_after_action :discard_flash_if_xhr # Suppress overwhelming Blacklight deprecation warning

  def set_no_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def mejs
    session['mejs_version'] = params[:version] === '4' ? 4 : 2
    flash[:notice] = "Using MediaElement Player Version #{session['mejs_version']}"
    redirect_to(root_path)
  end

  def rewrite_v4_ids
    return if params[:controller] =~ /migration/

    params.permit!
    new_id = ActiveFedora::SolrService.query(%{identifier_ssim:"#{params[:id]}"}, rows: 1, fl: 'id').first['id']
    new_content_id = params[:content] ? ActiveFedora::SolrService.query(%{identifier_ssim:"#{params[:content]}"}, rows: 1, fl: 'id').first['id'] : nil
    redirect_to(url_for(params.merge(id: new_id, content: new_content_id)))
  end

  def store_location
    store_location_for(:user, request.url)
    if request.env["omniauth.params"].present? && request.env["omniauth.params"]["login_popup"].present?
      session[:previous_url] = root_path + "self_closing.html"
    end
  end

  def after_sign_in_path_for(_resource)
    if request.env['QUERY_STRING']['login_popup'].present?
      root_path + "self_closing.html"
    else
      request.env['omniauth.origin'] || find_redirect_url(nil)
    end
  end

  # Used here and in omniauth_callbacks_controller
  def find_redirect_url(auth_type, lti_group: nil)
    previous_url = session.delete :previous_url
    if params['target_id']
      # Whitelist params that are allowed to be passed through via LTI
      objects_path(params['target_id'], params.permit('t', 'position', 'token'))
    elsif params[:url]
      # Limit redirects to current host only (Fixes bug https://bugs.dlib.indiana.edu/browse/VOV-5662)
      uri = URI.parse(params[:url])
      request.host == uri.host ? uri.path : root_path
    elsif auth_type == 'lti' && lti_group.present?
      search_catalog_path('f[read_access_virtual_group_ssim][]' => lti_group)
    elsif previous_url
      previous_url
    else
      root_path
    end
  end

  def handle_api_request
    if request.headers['Avalon-Api-Key'].present?
      token = request.headers['Avalon-Api-Key']
      #verify token (and IP)
      api_token = ApiToken.where(token: token).first
      unless api_token.nil?
        user = User.from_api_token(api_token)
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

  # Returns collections for current_user or requested user
  # @param [String] The user to match against (optional)
  # @return [Collection] Collections to which current_user or requested user has manage access
  def get_user_collections(user = nil)
    # return all collections to admin, unless specific user is passed in
    if can?(:manage, Admin::Collection)
      if user.blank?
        Admin::Collection.all
      else
        Admin::Collection.where("inheritable_edit_access_person_ssim" => user).to_a
      end
    else
      Admin::Collection.where("inheritable_edit_access_person_ssim" => user_key).to_a
    end
  end
  helper_method :get_user_collections

  # Returns milliseconds from a time string of format h:m:s.s or m:s.s or s.s
  # @param [String] The time string
  # @return [float] the time string converted to milliseconds
  def time_str_to_milliseconds(value)
    if value.is_a?(Numeric)
      value.floor
    elsif value.is_a?(String)
      result = 0
      segments = value.split(/:/).reverse
      begin
        segments.each_with_index { |v, i| result += i > 0 ? Float(v) * (60**i) * 1000 : (Float(v) * 1000) }
        result.to_i
      rescue
        return value
      end
    else
      value
    end
  end

  def current_ability
    session_opts ||= user_session
    session_opts ||= {}
    @current_ability ||= Ability.new(current_user, session_opts.merge(remote_ip: request.remote_ip))
  end

  rescue_from CanCan::AccessDenied do |exception|
    if request.format == :json
      head :unauthorized
    else
      session[:previous_url] = request.fullpath unless request.xhr?
      render '/errors/restricted_pid', status: :unauthorized
    end
  end

  rescue_from ActiveFedora::ObjectNotFoundError do |exception|
    if request.format == :json
      render json: {errors: ["#{params[:id]} not found"]}, status: 404
    else
      render '/errors/unknown_pid', status: 404
    end
  end

  rescue_from Ldp::Gone do |exception|
    if request.format == :json
      render json: {errors: ["#{params[:id]} has been deleted"]}, status: 410
    else
      render '/errors/deleted_pid', status: 410
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |user_params|
      user_params.permit(:username, :email, :password, :password_confirmation)
    end

    devise_parameter_sanitizer.permit(:sign_in) do |user_params|
      user_params.permit(:login, :password)
    end
  end

  def authenticate_user!(_opts = {})
    return if user_signed_in?
    if request.format == :json
      head :unauthorized
    else
      session[:previous_url] = request.fullpath unless request.xhr?
      redirect_to new_user_session_path(url: request.url), flash: { notice: 'You need to login to perform this action.' }
    end
  end

  def after_invite_path_for(_inviter, _invitee = nil)
    main_app.persona_users_path
  end

  def fetch_object(id)
    obj = ActiveFedora::Base.where(identifier_ssim: id.downcase).first
    obj ||= begin
              ActiveFedora::Base.find(id, cast: true)
            rescue ActiveFedora::ObjectNotFoundError, Ldp::BadRequest
              nil
            end
    obj || GlobalID::Locator.locate(id)
  end

  private

    def remove_zero_width_chars
      # params is a ActionController::Parameters
      strip_zero_width_chars!(params)
    end

    def strip_zero_width_chars!(obj)
      case obj
      when String
        obj.remove_zero_width_chars
      when Array
        obj.map! { |child| strip_zero_width_chars!(child) }
      when Hash
        obj.transform_values! { |value| strip_zero_width_chars!(value) }
      when ActionController::Parameters
        obj.each { |k, v| obj[k] = strip_zero_width_chars!(v) }
      else
        obj
      end
    end
end
