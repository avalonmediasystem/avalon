# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
  before_filter :store_location

  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  
  # Adds Hydra behaviors into the application controller 
  include Hydra::Controller::ControllerBehavior
  include AccessControlsHelper

  layout 'avalon'
  
  # Please be sure to implement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  protect_from_forgery

  after_filter :set_access_control_headers

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
    if can_embed?
      headers['X-Frame-Options'] = 'ALLOWALL'
    end
  end
  
  def can_embed?
    false # override in controllers for action-targeted embeds
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, user_session)
  end

  def store_location
    if request.env["omniauth.params"].present? && request.env["omniauth.params"]["login_popup"].present?
      session[:previous_url] = root_path + "self_closing.html"
    end
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  Warden::Manager.after_authentication do |user,auth,opts|
    auth.cookies[:signed_in] = 1
  end

  Warden::Manager.before_logout do |user,auth,opts|
    auth.cookies.delete :signed_in
  end

  rescue_from CanCan::AccessDenied do |exception|
    if current_user
      if exception.subject.class == MediaObject && exception.action == :update
        redirect_to exception.subject, flash: { notice: 'You are not authorized to edit this document.  You have been redirected to a read-only view.' }
      else
        redirect_to root_path, flash: { notice: 'You are not authorized to perform this action.' }
      end
    else
      session[:previous_url] = request.fullpath unless request.xhr?
      redirect_to new_user_session_path, flash: { notice: 'You are not authorized to perform this action. Try logging in.' }
    end
  end

  def get_user_collections
    if can? :manage, Admin::Collection
      Admin::Collection.all
    else
      Admin::Collection.where("#{ActiveFedora::SolrService.solr_name("inheritable_edit_access_person", Hydra::Datastream::RightsMetadata.indexer)}" => user_key).to_a
    end
  end
  helper_method :get_user_collections

end
