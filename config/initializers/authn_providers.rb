module Hydrant
	module Authentication
		Providers = YAML.load(File.read(File.expand_path('../../authentication.yml',__FILE__)))
	end
end