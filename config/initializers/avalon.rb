require 'string_additions'
require 'avalon/errors'
require 'human_readable_duration'
# Loads configuration information from the YAML file and then sets up the
# dropbox
#
# This makes a Dropbox object accessible in the controllers to query and find
# out what is available. See lib/avalon/dropbox.rb for details on the API
require 'avalon/dropbox'
require 'avalon/batch'

I18n.config.enforce_available_locales = true
