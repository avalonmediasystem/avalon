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

# Avalon::Authentication::Config/Providers are computed once, at module load
# time, from whatever Settings/ENV look like at boot -- not practical to
# re-trigger by mutating ENV in a spec. env_lti_config is extracted
# specifically so the one part of that boot-time logic worth guarding
# (the stale-env-var-silently-wins-over-settings.yml footgun found live on
# the UMD sandbox: LTI_AUTH_KEY left over from before settings.yml was set
# up for 1.3 appended a second, protocol-less :lti entry that won the "last
# config.omniauth :lti call wins" race, silently downgrading a working 1.3
# config to 1.1 with no error -- just a NotImplementedError deep inside
# OmniAuth's request phase at actual launch time) can be tested directly.
describe Avalon::Authentication do
  describe '.env_lti_config' do
    around do |example|
      old_key = ENV['LTI_AUTH_KEY']
      old_secret = ENV['LTI_AUTH_SECRET']
      example.run
      ENV['LTI_AUTH_KEY'] = old_key
      ENV['LTI_AUTH_SECRET'] = old_secret
    end

    context 'when LTI_AUTH_KEY is not set' do
      before { ENV.delete('LTI_AUTH_KEY') }

      it 'returns nil regardless of existing configs' do
        expect(Avalon::Authentication.env_lti_config([])).to be_nil
        expect(Avalon::Authentication.env_lti_config([{ provider: :lti }])).to be_nil
      end
    end

    context 'when LTI_AUTH_KEY is set and no :lti provider is already configured' do
      before do
        ENV['LTI_AUTH_KEY'] = 'somekey'
        ENV['LTI_AUTH_SECRET'] = 'somesecret'
      end

      it 'returns an LTI 1.1 provider config built from the env vars' do
        config = Avalon::Authentication.env_lti_config([{ provider: :saml }])
        expect(config[:provider]).to eq(:lti)
        expect(config[:params][:oauth_credentials]).to eq('somekey' => 'somesecret')
      end
    end

    context 'when LTI_AUTH_KEY is set and a settings.yml :lti provider already exists' do
      before { ENV['LTI_AUTH_KEY'] = 'stalekey' }

      it 'raises instead of silently producing a second, conflicting :lti config' do
        existing = [{ provider: :lti, protocol: '1.3' }]
        expect { Avalon::Authentication.env_lti_config(existing) }
          .to raise_error(/LTI_AUTH_KEY.*already configures an :lti provider/)
      end
    end
  end
end
