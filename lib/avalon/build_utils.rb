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

module Avalon

class BuildUtils

  COMMAND_BASE="podman image push"
  def initialize
  end

  def read_config_file
    script_path = __dir__

    parent = File.dirname( File.dirname(script_path) )
    file = "#{parent}/config/application.rb"
    contents = File.readlines(file)

  end

  def detect_version(contents="")
    contents = read_config_file if contents.empty?
    version = ""
    contents = contents.split("\n") if (contents.is_a? String )
    contents.each { |line|
      next if line[/^\s*#/]
      if match = line.match( /^\s*VERSION\s*=\s*['"](\d+\.\d+(\.\d+){1,2})['"]/ )
        version = match.captures[0]
      end
    }
    version
  end

  def get_tags(version, split=false, branch="", top_level=false, additional_tags="")
    tags = []
    parts = version.split('.')
    len = parts.length
    version_tags = []
    extra_tags = additional_tags.split(",")
    return if len < 2 || len > 4


    if split
      version_tags = split_parts(version)
      version_tags.each{|tag|
        if branch.empty?
          tags.push(tag)
        else
          tags.push "#{tag}-#{branch}"
        end
      }
    else
      version_tags.push(version) if top_level
      version = "#{version}-#{branch}" unless branch.empty?
      tags.push(version)
    end
    tags.concat(version_tags) if top_level
    tags.push(branch) unless branch.empty?
    tags.concat(extra_tags) unless extra_tags.nil? || extra_tags.empty?


    tags

  end

  def split_parts(version)
    parts = version.split('.')
    len = parts.length
    tags = []
    1.step{ |i|
      tag = parts.slice( 0, i ).join('.')
      tags.push(tag)
      break if i >= len
    }

    tags
  end

  def get_commands(tags, source, dest)
    commands = []
    tags.each{|tag|
      command = "#{COMMAND_BASE} #{source} #{dest}:#{tag} "
      commands.push(command)

    }
    commands

  end
end

end
