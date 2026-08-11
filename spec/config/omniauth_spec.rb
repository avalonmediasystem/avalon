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

# config/initializers/omniauth.rb overrides OmniAuth.config.request_validation_phase
# (a single global callable OmniAuth runs on every provider's request/callback
# phase) to skip the default CSRF/authenticity check for :lti specifically,
# since a third-party-initiated login arrives as a token-less cross-site POST
# from the LMS. Exercised directly against the configured lambda rather than
# through a full request to /users/auth/:provider: in this test environment
# (config.eager_load only true under CI) Devise's omniauth-middleware
# initializer runs before Avalon's to_prepare block registers the :lti
# provider, so the OmniAuth strategy middleware that would normally run this
# check on a live request is never actually inserted into the stack here --
# a full request spec would silently pass without exercising anything.
describe 'OmniAuth CSRF exemption' do
  # Minimal Rack env sufficient for Rack::Protection::AuthenticityToken#accepts?
  # to actually evaluate a POST with no token, rather than short-circuiting.
  def env_for(strategy_name)
    strategy = Struct.new(:name).new(strategy_name)
    Rack::MockRequest.env_for('/', method: 'POST').merge(
      'omniauth.strategy' => strategy,
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
