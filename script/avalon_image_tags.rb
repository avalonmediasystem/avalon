#!/usr/bin/env ruby
# frozen_string_literal: true

require("#{__dir__}/../lib/avalon/build_utils.rb")

# OPTIONS
#--version
#--branch
#--split-parts
#--additional-tags (or just all the rest?)

require 'optionparser'

version = ""
options = {}
options[:branch] = ""
options[:additonal_tags] = ""
options[:split] = false
options[:top_level] = false

help_text = ""
OptionParser.new do |opts|
  help_text = opts
  opts.banner = "Usage: avalon_image_tags.rb [options] [path]\nNOTE: You must provide a branch unless you specify --top-level" # "\nDefaults: dfm -xd ." + File::SEPARATOR
  opts.on("-v", "--version VERSION", "Version, in 1.2.3 format; will be detected if not provided") do |version_cli|
    version = version_cli
  end
  opts.on("-b", "--branch BRANCH", "Specifies what branch to use") do |branch_cli|
    options[:branch] = branch_cli
  end
  opts.on("-t", "--top-level", "Allows tagging top-level version tags (i.e. 1.2.3 with no branch; only for 'production' branch)") do
    options[:top_level] = true
  end
  opts.on("-a", "--additional-tags TAGS", "Additional tags, comma-separated (no spaces)") do |tags_cli|
    options[:additional_tags] = tags_cli
  end
  opts.on("-s", "--split", "Split version number, i.e. 1.2.3 becomes 1.2.3,1.2,1") do
    options[:split] = true
  end
end.parse!

if !options[:top_level] && (options[:branch].nil? || options[:branch].empty?)
 warn "Error: must supply --branch and/or --top-level\n"
 warn help_text
 exit 1
end

utils = Avalon::BuildUtils.new
version = utils.detect_version if version.empty?
tags = utils.get_tags(version, options)

puts tags
