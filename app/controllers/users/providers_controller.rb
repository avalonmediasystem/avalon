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

class Users::ProvidersController < ApplicationController

  def login
    logger.info "in omniauth callback after logging in"
    
    #4/25/16 current implemented provider is "CAS" 
    params[:provider] ? provider = params[:provider] : provider = ""
    user_info = getExtraFromLDAP(request.env["omniauth.auth"].uid)
    user_info["mail"] ? email = user_info["mail"][0] : email = ""
    user_info["uid"] ? username = user_info["uid"][0] : username = ""
    logger.info "provider: #{provider}"
    logger.info "email: #{email}"
    logger.info "username: #{username}"

    if provider.present? == false || email.present? == false || username.present? == false
      logger.error "missing key info - provider, email, username"
      flash[:error] = "Error retrieving user information"
      redirect_to root_path and return
    end
    #service = Service.find_by_provider_uid(provider,uid)
    user = User.where(provider: provider,username: username)
    if user.empty? == false
      logger.info "signing in as user #{user.inspect}"
      if user[0].email != email
        logger.info "email from ldap #{email} doesn't match email in this app #{user[0].email}, update."
        user[0].email = email
        user[0].save!
      end
      flash[:notice] = "Signed in successfully via #{provider.upcase} as #{username} with email #{email}."
      sign_in_and_redirect(user[0]) and return
    else
      logger.info "no user found, creating #{provider.upcase} user #{username} email #{email}"
      user = User.new(:username => username, :provider => provider, :email => email)
      user.save!
      flash[:notice] = "Sign in via #{provider.upcase} has been added to your account #{username} with email #{email}."
      sign_in_and_redirect(user) and return
    end
    logger.error "Something went wrong on login."
    flash[:error] = "Something went wrong on login.  Contact administrator"    
    redirect_to root_path and return
  end

  def logout
    logger.info "logging out of cas"
    sign_out(current_user)
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

  private

end
