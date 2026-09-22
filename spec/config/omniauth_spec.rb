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

require 'rails_helper'

# config/initializers/devise.rb overrides OmniAuth.config.request_validation_phase
# (a single global callable OmniAuth runs on every provider's request/callback
# phase) to skip the default CSRF/authenticity check for :lti specifically,
# since a third-party-initiated login arrives as a token-less cross-site POST
# from the LMS.
describe 'OmniAuth CSRF exemption' do
  # Minimal Rack env sufficient for Rack::Protection::AuthenticityToken#accepts?
  # to actually evaluate a POST with no token, rather than short-circuiting.
  def env_for(strategy_name)
    Rack::MockRequest.env_for('/', method: 'POST').merge(
      'omniauth.strategy' => double('strategy', name: strategy_name),
      'rack.session' => {}
    )
  end

  it 'does not run the authenticity check for the :lti strategy' do
    expect { OmniAuth.config.request_validation_phase.call(env_for('lti')) }.not_to raise_error
  end

  it 'still runs the default authenticity check for other strategies' do
    expect { OmniAuth.config.request_validation_phase.call(env_for('identity')) }
      .to raise_error(OmniAuth::AuthenticityError)
  end
end

# The exemption above is also exercised through the real, live middleware
# stack -- unlike when this spec was first written, the :lti strategy is
# genuinely mounted in Rails.application.middleware in this test environment
# (see spec/config/omniauth_middleware_spec.rb), so a request spec here
# actually exercises OmniAuth's enforcement path rather than calling the
# configured lambda directly.
describe 'CSRF handling on the live LTI request phase', type: :request do
  it 'does not fail with an authenticity error when POSTed without a CSRF token' do
    post '/users/auth/lti'
    # Checking the exception object itself, not just that the request
    # "succeeded": omniauth.error.type is a symbolized exception *message*,
    # not a fixed error code, and here it's nil regardless of the CSRF
    # exemption -- the 1.1 strategy doesn't implement request_phase, and
    # that NotImplementedError is a ScriptError, not a StandardError, so it
    # isn't caught by OmniAuth's fail! and never touches omniauth.error at
    # all. AuthenticityError is a StandardError and would be caught and
    # recorded here, so this still fails correctly if the exemption breaks.
    expect(request.env['omniauth.error']).not_to be_a(OmniAuth::AuthenticityError)
  end
end
