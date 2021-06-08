# You also need to explicitly enable OAuth 1 support in the environment.rb or an initializer:
AUTH_10_SUPPORT = true

module Avalon
  module Lti
    begin
      Configuration =
        YAML.load(ERB.new(File.read(File.expand_path('../../lti.yml', __FILE__))).result)
    rescue
      Configuration = {}
    end
    puts "LTI Configuration #{Configuration}"
  end
end
