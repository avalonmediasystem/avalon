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


module Avalon
  module Authentication
    def self.lti_configured?
      Devise.omniauth_providers.include?(:lti)
    end

    def self.load_configs
      configs = Settings&.auth&.configuration
      if configs.blank?
        []
      elsif configs.is_a?(Array)
        configs.collect(&:to_hash)
      else
        configs.to_hash.values
      end
    end

    # Legacy single-consumer LTI 1.1 config via env vars, predating
    # settings.yml's richer auth.configuration. Kept for backward compatibility,
    # but combining it with a settings.yml :lti entry is virtually always a
    # mistake -- usually a stale env var left over from before settings.yml was
    # set up for LTI. Devise only ever binds one strategy per provider key, so
    # whichever entry registers last (array order, not anything explicit)
    # silently wins, with no error, just the wrong protocol at actual launch
    # time -- e.g. NotImplementedError deep inside OmniAuth's request phase when
    # a 1.3 config's requests get handled by the 1.1 strategy. Fail loudly at
    # boot instead.
    def self.env_lti_config(existing_configs)
      return nil unless ENV['LTI_AUTH_KEY']

      if existing_configs.any? { |provider| provider[:provider] == :lti }
        raise "LTI_AUTH_KEY/LTI_AUTH_SECRET are set, but settings.yml (auth.configuration) " \
              "already configures an :lti provider. Only one :lti configuration is supported " \
              "at a time -- remove the stale LTI_AUTH_KEY/LTI_AUTH_SECRET env vars, or remove " \
              "the :lti entry from settings.yml."
      end

      { name: 'LTI', provider: :lti, hidden: true, params: { oauth_credentials: { ENV['LTI_AUTH_KEY'] => ENV['LTI_AUTH_SECRET'] } } }
    end

    Config = load_configs
    if (env_config = env_lti_config(Config))
      Config << env_config
    end

    Providers = Config.reject {|provider| provider[:provider].blank? }
    VisibleProviders = Providers.reject {|provider| provider[:hidden]}
    HiddenProviders = Providers - VisibleProviders
  end
end
