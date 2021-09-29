# You also need to explicitly enable OAuth 1 support in the environment.rb or an initializer:
# AUTH_10_SUPPORT = true

module Avalon
  module Saml
    begin
      config_file = "../../saml.yml"
      config_path = File.expand_path(config_file, __FILE__ )
        #YAML.load(ERB.new(File.read(File.expand_path('../../lti.yml', __FILE__))).result)
      Configuration =
        YAML.load(ERB.new(File.read(config_path)).result)
      puts "Saml Configuration: #{Configuration}"
    rescue
      puts "FAILED LOADING FILE #{config_path}"
      Configuration = {}
    end
  end
end
