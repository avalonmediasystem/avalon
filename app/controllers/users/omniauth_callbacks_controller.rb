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

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # The default OmniAuth forms don't provide CSRF tokens, so we can't verify
  # them. Trying to verify results in a cleared session.
  skip_before_filter :verify_authenticity_token

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

  def method_missing(sym, *args, &block)
    logger.debug "Attempting to find user with #{sym.to_s} strategy"
    find_user(sym.to_s)
  end

  def find_user(auth_type)
    auth_type.downcase!
    find_method = "find_for_#{auth_type}".to_sym
    logger.debug "#{auth_type} :: #{current_user.inspect}"
  	@user = User.send(find_method,request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => auth_type
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.#{auth_type}_data"] = request.env["omniauth.auth"]
      redirect_to root_url #Have this redirect someplace better like IU CAS guest account creation page
    end
  end
  protected :find_user
end
