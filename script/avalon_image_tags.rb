# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

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
