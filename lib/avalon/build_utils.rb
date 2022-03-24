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
    # puts "script_path: #{script_path}"

    parent = File.dirname( File.dirname(script_path) )
    file = "#{parent}/config/application.rb"
    # puts "parent: #{parent}"
    # puts "file: #{file}"
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
      # || ""; break  if line[/^\s*VERSION\s*=\s*['"]/]
        # version = $1
      end
      #puts "verwion is #{version}"
    }
    version
  end

  def get_tags(version, additional_tags="")
    tags = []
    parts = version.split('.')
    len = parts.length
    return if len < 2 || len > 4


    1.step{ |i|
      #puts "parts[i] #{parts[i]}"
      tag = parts.slice( 0, i ).join('.')
      # puts "tag: #{tag}"
      tags.push(tag)
      break if i >= len
    }
    tags.push(additional_tags) unless additional_tags.nil? || additional_tags.empty?


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
