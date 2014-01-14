module Avalon
	module Authentication
		Providers  = YAML.load(File.read(File.expand_path('../../authentication.yml',__FILE__)))
	  VisibleProviders = Providers.reject {|provider| provider[:hidden]}
    HiddenProviders = Providers - VisibleProviders
  end
end
