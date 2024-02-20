# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

#!/usr/bin/env ruby
# frozen_string_literal: true

# Provides utilities for detecting the Avalon version
# and get tags for images, and pushing to repos
# Intended to be used without having run
# bundle install, so uses no external gems

# Detects the Avalon version by grepping
# through config/application.rb
# Version should be sematic format like this:
# major.minor.patch.build
# Must have at least major.minor
# Supported examples:
# 7.3
# 7.3.0
# 7.3.0.15

module Avalon
  class BuildUtils
    COMMAND_BASE = "podman image push"

    def initialize; end

    def read_config_file
      script_path = __dir__
      parent = File.dirname(File.dirname(script_path))
      file = "#{parent}/config/application.rb"
      File.readlines(file)
    end

    def detect_version(contents = "")
      contents = read_config_file if contents.empty?
      contents = contents.split("\n") if contents.is_a? String
      version = extract_version_from_lines contents
      version
    end

    def extract_version_from_lines(lines = [])
      version = ""
      lines.each do |line|
        next if line[/^\s*#/]
        if (match = line.match(/^\s*VERSION\s*=\s*['"](\d+\.\d+(\.\d+){1,2})['"]/))
          version = match.captures[0]
        end
      end
      version
    end

    def clean_option_values(options)
      options[:branch] = options[:branch] || ""
      options[:top_level] = options[:top_level] || false
      options[:additional_tags] = options[:additional_tags] || ""
      options[:split] = options[:split] || false
      options
    end

    def get_tags(version, options = {})
      options = clean_option_values options

      # if top level isn't enabled and there is no branch specified,
      # return an empty array, as there will be no tags
      return [] if options[:branch].empty? && !options[:top_level]

      # additional_tags = options[:additional_tags]
      extra_tags = options[:additional_tags].split(",")
      parts = version.split('.')
      len = parts.length

      # only accept between 2 and 4 parts
      return if len <= 2 || len > 4

      tags = get_version_tags(version, options)
      tags.push(options[:branch]) unless options[:branch].empty?
      tags.concat(extra_tags) unless extra_tags.empty?
      # enforce uniqueness and sort to ensure ordering consistency
      tags = tags.uniq.sort
      tags.join(",")
    end

    def get_version_tags(version, options)
      options = clean_option_values options
      version_tags = []
      if options[:split]
        tags = split_parts(version)
        tags.each do |tag|
          version_tags.push(tag) if options[:top_level]
          version_tags.push "#{tag}-#{options[:branch]}" unless options[:branch].empty?
        end
      else
        version_tags.push(version) if options[:top_level]
        branch_tag = ""
        branch_tag = "#{version}-#{options[:branch]}" unless options[:branch].empty?
        version_tags.push(branch_tag) unless branch_tag.empty?
        version_tags.concat(version_tags) if options[:top_level]
      end
      version_tags
    end

    def split_parts(version)
      parts = version.split('.')
      len = parts.length
      tags = []
      1.step do |i|
        tag = parts.slice(0, i).join('.')
        tags.push(tag)
        break if i >= len
      end
      tags
    end
  end
end
