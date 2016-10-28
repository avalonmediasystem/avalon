module Avalon
  module Authentication
    def self.lti_configured?
      Devise.omniauth_providers.include?(:lti)
    end
    Config  = YAML.load(File.read(File.expand_path('config/authentication.yml',Rails.root)))
    Providers = Config.reject {|provider| provider[:provider].blank? }
    VisibleProviders = Providers.reject {|provider| provider[:hidden]}
    HiddenProviders = Providers - VisibleProviders
  end
end
