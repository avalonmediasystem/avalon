# Loads configuration information from the YAML file and then sets up the
# dropbox so that it can monitor using the guard-hydrant gem
#
# This makes a Dropbox object accessible in the controllers to query and find
# out what is available. See lib/hydrant/dropbox.rb for details on the API 
require 'hydrant/dropbox'

module Hydrant
  Configuration = YAML::load(File.read(Rails.root.join('config', 'hydrant.yml')))
  DropboxService = Dropbox.new Hydrant::Configuration['dropbox']['path']
end
