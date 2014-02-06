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

  def action_missing(sym, *args, &block)
    logger.debug "Attempting to find user with #{sym.to_s} strategy"
    find_user(sym.to_s)
  end

  def find_user(auth_type)
    binding.pry
    auth_type.downcase!
    find_method = "find_for_#{auth_type}".to_sym
    logger.debug "#{auth_type} :: #{current_user.inspect}"
    @user = User.send(find_method,request.env["omniauth.auth"], current_user)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => auth_type
      sign_in @user, :event => :authentication

      if auth_type == 'lti'
        user_session[:virtual_groups] = [request.env["omniauth.auth"].extra.context_id]
        user_session[:full_login] = false
      end
    end

    if request['media_object_id']
      redirect_to media_object_path(request['media_object_id'])
    elsif session[:previous_url] 
      redirect_to session.delete :previous_url
    elsif user_session[:virtual_groups].present?
      redirect_to catalog_index_path('f[read_access_virtual_group_ssim][]' => user_session[:virtual_groups].first)
    else
      redirect_to root_url
    end
  end

  protected :find_user
end
