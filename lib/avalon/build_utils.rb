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
    COMMAND_BASE="podman image push"

    def initialize; end

    def read_config_file
      script_path = __dir__
      parent = File.dirname(File.dirname(script_path))
      file = "#{parent}/config/application.rb"
      File.readlines(file)
    end

    def detect_version(contents = "")
      contents = read_config_file if contents.empty?
      version = ""
      contents = contents.split("\n") if contents.is_a? String
      contents.each do |line|
        next if line[/^\s*#/]
        if match = line.match(/^\s*VERSION\s*=\s*['"](\d+\.\d+(\.\d+){1,2})['"]/)
          version = match.captures[0]
        end
      end
      version
    end

    def get_tags(version, options = {})

      split = options[:split] || false
      branch = options[:branch] || ""
      top_level = options[:top_level] || false
      additional_tags_str = options[:additional_tags]
      additional_tags_str ||= ""
      extra_tags = additional_tags_str.split(",")
      parts = version.split('.')
      len = parts.length

      # only accept between 2 and 4 parts
      return if len < 2 || len > 4

      # if top level isn't enabled and there is no branch specified,
      # return an empty array, as there will be no tags
      return [] if branch.empty? && !top_level

      version_tags = []
      tags = []
      if split
        version_tags = split_parts(version)
        version_tags.each do |tag|
          # unshift to add the version tags to the start of the result
          # purely for human readability reasons
          tags.unshift(tag) if top_level
          tags.push "#{tag}-#{branch}" unless branch.empty?
        end
      else
        version_tags.push(version) if top_level
        branch_tag = ""
        branch_tag = "#{version}-#{branch}" unless branch.empty?
        tags.push(branch_tag) unless branch_tag.empty?
        tags.concat(version_tags) if top_level
      end

      tags.push(branch) unless branch.empty?
      tags.concat(extra_tags) unless extra_tags.empty?

      tags

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
