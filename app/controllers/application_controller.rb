# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller  
  # Adds Hydra behaviors into the application controller 
  include Hydra::Controller::ControllerBehavior
  include AccessControlsHelper

  layout 'avalon'
  
  # Please be sure to implement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 
  protect_from_forgery
  
  before_filter :trap_session_information if 
    (Rails.env.development? or Rails.env.test?)
  after_filter :set_access_control_headers
  
  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end
  
  def trap_session_information
    logger.debug "<< CURRENT SESSION INFORMATION >>"
    logger.debug session.inspect
  end

  def set_parent_name!
    @parent_name =  params[:controller].to_s.split('/')[-2..-2].try :first
  end

  def find_managers!(params)
    Select2::Autocomplete.param_to_array(params[:managers]).map do |uid|

      user_from_directory = Avalon::UserSearch.new.find_by_uid( uid )
      raise "Could not find user in directory with uid: #{uid}" unless user_from_directory
      
      user = User.find_by_uid(uid)
      user ||= User.find_by_email(user_from_directory[:email]) if user_from_directory[:email]
      
      if ! user
        user = User.new
        user.guest = true
      end

      # create or update user information based upon what is available
      user.email = user_from_directory[:email]
      user.username = user_from_directory[:email] || user_from_directory[:uid] #cannot be blank
      user.full_name = user_from_directory[:full_name]
      user.uid = user_from_directory[:uid]
      user.save!

      user
    end if params[:managers]
  end
end
