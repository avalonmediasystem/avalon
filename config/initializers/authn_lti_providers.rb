# You also need to explicitly enable OAuth 1 support in the environment.rb or an initializer:
AUTH_10_SUPPORT = true

module Avalon
	module Authentication
		LtiProviders = YAML.load(File.read(File.expand_path('../../authentication_lti.yml',__FILE__)))
	end
end
