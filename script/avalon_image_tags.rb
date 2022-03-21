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

#version = ARGV[0]
additional_tags = ARGV.slice(0,ARGV.length) if ARGV.length >= 1

#puts "additional_tags #{additional_tags}"

utils = AvalonVersionUtils.new
version = utils.detect_version
tags = utils.get_tags(version, additional_tags)

#puts version
#puts "TAGS"
#puts tags
puts tags.join(",")
