#!/usr/bin/env ruby

require("#{__dir__}/../lib/avalon/build_utils.rb")

# OPTIONS
#--version
#--branch
#--split-parts
#--additional-tags (or just all the rest?)

require 'optionparser'
options = {}
printers = Array.new
branch = ""
additional_tags = ""
parts = false
top_level = false

OptionParser.new do |opts|
  opts.banner = "Usage: avalon_image_tags.rb [options] [path]" # "\nDefaults: dfm -xd ." + File::SEPARATOR
  opts.on("-v", "--version VERSION", "Version, in 1.2.3 format") do |version_cli|
    version = version_cli
  end
  opts.on("-b", "--branch BRANCH", "Prints duplicate files by MD5 hexdigest") do |branch_cli|
    branch = branch_cli
  end
  opts.on("-t", "--top-level", "Allows tagging top-level version tags (i.e. 1.2.3 with no branch; only for production use)") do |top_cli|
    top_level = true
  end
  opts.on("-a", "--additional-tags TAGS", "Additional tags, comma-separated (no spaces)") do |tags_cli|
    additional_tags = tags_cli
  end
  opts.on("-s", "--split-parts", "Split version number, i.e. 1.2.3 becomes 1.2.3,1.2,1 - only for production branch, usually") do |dh|
    parts = true
  end
end.parse!


utils = Avalon::BuildUtils.new
version = utils.detect_version
tags = utils.get_tags(version, parts, branch, top_level, additional_tags)

puts tags.join(",")

tags
