# You also need to explicitly enable OAuth 1 support in the environment.rb or an initializer:
# AUTH_10_SUPPORT = true

module Avalon
  module Saml
    begin
      config_file = "../../saml.yml"
      config_path = File.expand_path(config_file, __FILE__ )
      Configuration =
        YAML.load(ERB.new(File.read(config_path)).result)
    rescue
      Configuration = {}
    end
  end
end
