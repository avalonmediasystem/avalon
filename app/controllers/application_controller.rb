# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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
  before_filter :store_location, unless: :devise_controller?

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  layout 'avalon'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery unless: proc{|c| request.headers['Avalon-Api-Key'].present? }

  helper_method :render_bookmarks_control?

  around_action :handle_api_request, if: proc{|c| request.format.json?}

  def store_location
    store_location_for(:user, request.url)
      if request.env["omniauth.params"].present? && request.env["omniauth.params"]["login_popup"].present?
        session[:previous_url] = root_path + "self_closing.html"
      end
  end

  def after_sign_in_path_for(resource)
    if request.env['QUERY_STRING']['login_popup'].present?
      root_path + "self_closing.html"
    else
      request.env['omniauth.origin'] || stored_location_for(resource) || session[:previous_url] || root_path
    end
  end

  def current_ability
    session_opts ||= user_session
    session_opts ||= {}
    @current_ability ||= Ability.new(current_user, session_opts.merge(remote_ip: request.remote_ip))
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

  def get_user_collections
    if can? :manage, Admin::Collection
      Admin::Collection.all
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

  rescue_from Ldp::Gone do |exception|
    if request.format == :json
      render json: {errors: ["#{params[:id]} has been deleted"]}, status: 410
    else
      render '/errors/deleted_pid', status: 410
    end
  end
end
