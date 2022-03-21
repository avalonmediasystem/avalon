#!/usr/bin/env ruby

# Detects the Avalon version by grepping
# through config/application.rb
# Version should be sematic format like this:
# major.minor.patch.build
# Must have at least major.minor
# Supported examples:
# 7.3
# 7.3.0
# 7.3.0.15
require("#{__dir__}/avalon_version_functions.rb")
utils = AvalonVersionUtils.new
#contents = utils.read_config_file
#puts "contents #{contents}"
version = utils.detect_version
puts version
