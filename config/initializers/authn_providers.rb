module Avalon
  module Authentication
    Config  = YAML.load(File.read(File.expand_path('../../authentication.yml',__FILE__)))
    Providers = Config.reject {|provider| provider[:provider].blank? }
    VisibleProviders = Providers.reject {|provider| provider[:hidden]}
    HiddenProviders = Providers - VisibleProviders
  end
end
