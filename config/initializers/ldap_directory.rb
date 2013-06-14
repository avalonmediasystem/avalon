module Avalon
  module Authentication
    NULAP_DIRECTORY = YAML.load(File.read(File.expand_path('../../nuldap_directory.yml',__FILE__)))
  end
end