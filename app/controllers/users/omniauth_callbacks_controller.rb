# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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
  skip_before_action :verify_authenticity_token

  def passthru
    begin
      render "modules/#{params[:provider]}_auth_form"
    rescue ActionView::MissingTemplate
      redirect_to new_user_session_path, flash: { alert: I18n.t('devise.failure.invalid') }
    end
  end

  def after_omniauth_failure_path_for(scope)
    case failed_strategy.name
    when 'lti'
      uri = lti_failure_return_uri
      return new_user_session_path(scope) unless uri

      default_msg = I18n.t 'devise.omniauth_callbacks.failure', reason: failure_message
      msg = I18n.t 'devise.omniauth_callbacks.lti.failure', default: default_msg
      uri.query = {lti_errormsg: msg}.to_query
      uri.to_s
    else
      new_user_session_path(scope)
    end
  end

  # Picks the best available "return to the LMS" URL for a failed LTI launch
  # and validates it's safe to redirect to, returning nil if it isn't (the
  # caller falls back to the sign-in page).
  #
  # 1.1 sends launch_presentation_return_url as a flat launch param. 1.3 has
  # no equivalent at this stage: the comparable value lives inside the
  # launch_presentation claim of the id_token, which a failed launch may
  # never have gotten far enough to decode. target_link_uri is the one
  # return-ish value 1.3 guarantees as a flat param up front (Step 1, the
  # third-party-initiated login), so it's the best available fallback.
  #
  # The param is an unauthenticated, attacker-controlled request value at
  # this point -- verification failed, so nothing here has been vouched for
  # yet. Without a same-host check this is an open redirect (POST a
  # registered iss with return_url=https://evil.com and a launch that's
  # guaranteed to fail, e.g. no login_hint) that would also leak
  # failure_message (which can include the registered client_id/issuer) via
  # lti_errormsg to that off-host destination. Same guard as
  # ApplicationController#find_redirect_url (VOV-5662). A malformed value
  # (e.g. an unescaped space in the host) makes Addressable raise rather
  # than just fail the host check, so that's treated the same way: not usable.
  private def lti_failure_return_uri
    param_name = failed_strategy.is_a?(OmniAuth::Strategies::Lti13) ? 'target_link_uri' : 'launch_presentation_return_url'
    return_url = request[param_name]
    return nil if return_url.blank?

    uri = Addressable::URI.parse(return_url)
    return nil unless request.host == uri.host

    uri
  rescue Addressable::URI::InvalidURIError
    nil
  end

  def action_missing(sym, *args, &block)
    logger.debug "Attempting to find user with #{sym.to_s} strategy"
    find_user(sym.to_s)
  end

  def login_popup?
    params['login_popup'].present? || (request.env["omniauth.params"].present? && request.env["omniauth.params"]["login_popup"].present?)
  end

  def find_user(auth_type)
    auth_type = auth_type.downcase
    find_method = "find_for_#{auth_type}".to_sym
    find_method = :find_for_generic unless User.respond_to?(find_method)
    logger.debug "#{auth_type} :: #{current_user.inspect}"
    @user = User.send(find_method,request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:success] = I18n.t "devise.omniauth_callbacks.success", :kind => auth_type
      sign_in @user, :event => :authentication
      user_session[:virtual_groups] = @user.ldap_groups
      user_session[:full_login] = true

      if auth_type == 'lti'
        # The context claim (and so context_id) is optional in the LTI spec --
        # a launch from outside a course context omits it -- so don't add a
        # nil to virtual_groups.
        context_id = request.env["omniauth.auth"].extra.context_id
        user_session[:lti_group] = context_id
        user_session[:virtual_groups] += [context_id] if context_id.present?
        user_session[:full_login] = false
      end
    end

    if login_popup?
      flash[:success] = nil
      render inline: "<html><head><script nonce='#{content_security_policy_nonce}'>window.close();</script></head><body></body><html>".html_safe
    else
      redirect_to find_redirect_url(auth_type, lti_group: user_session&.dig(:lti_group))
    end
  end

  protected :find_user

  rescue_from Avalon::MissingUserId do |exception|
    support_email = Settings.email.support
    notice_text = I18n.t('errors.lti_auth_error') % [support_email, support_email]
    redirect_to root_path, flash: { error: notice_text.html_safe }
  end

  rescue_from Avalon::MissingUserEmail do |exception|
    support_email = Settings.email.support
    notice_text = I18n.t('errors.lti_missing_email_error') % [support_email, support_email]
    redirect_to root_path, flash: { error: notice_text.html_safe }
  end

  rescue_from Avalon::DeletedUserId do |exception|
    support_email = Settings.email.support
    notice_text = I18n.t('errors.deleted_auth_error') % [support_email, support_email]
    redirect_to root_path, flash: { error: notice_text.html_safe }
  end

  rescue_from OAuth::Signature::UnknownSignatureMethod do |exception|
    notice_text = I18n.t('errors.general_auth_error')
    redirect_to root_path, flash: { error: notice_text }
  end
end
