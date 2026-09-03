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

# LTI is a third-party-initiated login: the browser arrives at Avalon via a
# cross-site POST from the LMS, so the session cookie set on that response
# must carry SameSite=None or the browser drops it and the user never
# actually ends up signed in. Avalon uses activerecord-session_store, whose
# cookie Rack builds directly and never stamps with a SameSite attribute of
# its own -- config.action_dispatch.cookies_same_site_protection has no
# effect on it (that setting only governs ActionDispatch::Cookies-managed
# cookies and Rails' built-in :cookie_store session type, neither of which
# this app uses for its session). Since the raw cookie never has a SameSite
# attribute to begin with, rails_same_site_cookie's "add SameSite=None
# unless already present" middleware always fires for it, unconditionally.
# This guards that behavior via a normal sign-in (provider-agnostic --
# nothing here is LTI-specific) rather than the OmniAuth callback itself,
# which needs a registered LTI Platform/consumer to launch for real.
describe 'session cookie SameSite handling', type: :request do
  let(:user) { FactoryBot.create(:user) }
  # rails_same_site_cookie explicitly skips modern Chrome over a non-SSL
  # request (`next if !ssl && parser.chrome?` -- Chrome historically mishandled
  # SameSite=None if it wasn't paired with Secure, so the gem won't emit one
  # without the other for Chrome specifically). A UA-less/HTTP request, as a
  # generic RSpec request-spec client, never touches that branch and would
  # pass even if this were broken for real browsers. Chrome + HTTPS matches
  # what an actual LMS-initiated launch looks like in production.
  let(:chrome_user_agent) do
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  end

  it 'sets the session cookie with SameSite=None and Secure for Chrome over HTTPS' do
    https!
    post '/users/sign_in',
         params: { user: { login: user.username, password: user.password }, admin: true, email: true },
         headers: { 'User-Agent' => chrome_user_agent }

    set_cookie = Array(response.headers['Set-Cookie'])
    session_cookie = set_cookie.find { |c| c.start_with?(Rails.application.config.session_options[:key]) }

    expect(session_cookie).to be_present
    expect(session_cookie).to match(/SameSite=None/i)
    expect(session_cookie).to match(/;\s*Secure/i)
  end
end
