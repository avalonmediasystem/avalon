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

# Regression guard for the bug fixed by unwrapping config/initializers/devise.rb
# from Rails.application.reloader.to_prepare (see afa7eb51c upstream, and the
# LTI 1.3 launch failure it caused here): Devise's own "devise.omniauth"
# initializer, which reads Devise.omniauth_configs and pushes each configured
# strategy onto the middleware stack, runs before: :build_middleware_stack.
# A to_prepare callback body doesn't execute until after the stack is already
# built, so if provider registration (config.omniauth :lti, ...) is wrapped in
# to_prepare, Devise.omniauth_configs looks correctly populated after boot,
# but no strategy middleware ever actually lands in the request-serving stack
# -- launches fall through to the generic passthru action instead of being
# intercepted, and just redirect to /users/sign_in.
describe 'OmniAuth strategy middleware' do
  it 'inserts the :lti strategy into the actual request-serving middleware stack' do
    middleware_classes = Rails.application.middleware.to_a.map(&:klass)
    expect(middleware_classes).to include(Devise.omniauth_configs[:lti].strategy_class)
  end
end

# Regression guard for a second, related boot-order bug found live against a
# real Moodle launch -- see the OmniAuth.config.path_prefix comment in
# config/initializers/devise.rb for the full mechanism. Asserted here
# directly against a fresh strategy instance rather than via
# Rails.application.middleware, to guard path_prefix correctness independent
# of route state, matching how the live bug actually manifested.
describe 'OmniAuth path_prefix' do
  it 'is set correctly without depending on routes having been drawn' do
    expect(OmniAuth.config.path_prefix).to eq('/users/auth')
  end

  it 'gives a freshly-instantiated :lti strategy the correct request/callback paths' do
    strategy = Devise.omniauth_configs[:lti].strategy_class.new(->(_env) { [200, {}, ['ok']] })
    expect(strategy.request_path).to eq('/users/auth/lti')
    expect(strategy.callback_path).to eq('/users/auth/lti/callback')
  end
end
