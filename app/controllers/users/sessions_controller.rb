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

class Users::SessionsController < Devise::SessionsController
  def new
    if Avalon::Authentication::VisibleProviders.length == 1
      redirect_to user_omniauth_authorize_path(Avalon::Authentication::VisibleProviders.first[:provider], params)
    else
      super
    end
  end

  def destroy
    StreamToken.logout! session
    super
    flash[:success] = flash[:notice]
    flash[:notice] = nil
  end

  def login
    logger.info "in omniauth callback after logging in"
    
    params[:provider] ? provider = params[:provider] : provider = ""
    user_info = getExtraFromLDAP(request.env["omniauth.auth"].uid)
    user_info["mail"] ? email = user_info["mail"][0] : email = ""
    user_info["uid"] ? uid = user_info["uid"][0] : uid = ""
    logger.info "provider: #{provider}"
    logger.info "email: #{email}"
    logger.info "uid: #{uid}"
    redirect_to root_path
  end

  def logout
    logger.info "logging out of cas"
    redirect_to 'https://secure.its.yale.edu/cas/logout'
  end

  protected

  def getExtraFromLDAP(netid)
    begin
      require 'net/ldap'
      ldap = Net::LDAP.new( :host =>"directory.yale.edu" , :port =>"389" )
      f = Net::LDAP::Filter.eq('uid', netid)
      b = 'ou=People,o=yale.edu'
      p = ldap.search(:base => b, :filter => f, :return_result => true).first
    rescue Exception => e
      return
    end
    return p
  end
end
