# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

namespace :avalon do
  namespace :tools do
    ffmpeg_path    = Settings.ffmpeg.path || "/usr/bin/ffmpeg"
    mediainfo_path = Settings.mediainfo.path || "/usr/bin/mediainfo"
    DEFAULT_TOOLS = [
      { name: "ffmpeg", path: ffmpeg_path, version_params: "-version", version_string: ">= 4", version_trim_pre: "ffmpeg version ", version_trim_last_char: "-" },
      { name: "mediainfo", path: mediainfo_path, version_string: "> 18", version_line: 1, version_trim_pre: "MediaInfoLib - v" },
      { name: "node", path: "/usr/bin/node", version_string: ">= 12", version_trim_pre: "v" },
      { name: "yarn", path: "/usr/bin/yarn", version_string: ">= 1.20" }
    ].freeze

    DEFAULT_VERSION_PARAMS = "--version".freeze

    def get_version_numeric(version_string)
      parts = version_string.split(".")
      major = parts[0] || 0
      minor = parts[1] || 0
      patch = parts[2] || 0

      "#{major}.#{minor}#{patch}".to_f
    end

    desc "List third-party tools"
    task list: :environment do
      puts "Listing third-party tools ..."

      tools = DEFAULT_TOOLS
      tools.each do |tool|
        puts "\nTOOL: #{tool[:name]}"
        params = tool[:version_params] || "--version"
        command = "#{tool[:path]} #{params}"
        puts "path: #{tool[:path]}"
        puts "version_command: #{command}"
        puts "file_exists: #{File.file?(tool[:path])}"
        output = `#{command}` || ""
        line = tool[:version_line] || 0
        if output.present?
          puts "file_executes: true"
          version = output.lines[line]
          puts "version: #{version}"
          version_parsed = version
          version_parsed = version_parsed.delete_prefix(tool[:version_trim_pre]) if tool[:version_trim_pre]
          version_parsed = version_parsed.partition(tool[:version_trim_last_char]).first if tool[:version_trim_last_char]
          puts "version_parsed: #{version_parsed}"
          puts "version_string: #{tool[:version_string]}" if tool[:version_string]
          version_num = get_version_numeric(version_parsed)
          requirements = tool[:version_string].split(" ")
          operator = requirements[0]
          requirement_version = requirements[1]
          requirement_num = get_version_numeric(requirement_version)
          puts "version_numeric: #{version_num}"
          puts "requirement_numeric: #{requirement_num}"
          requirement_met = version_num.public_send(operator, requirement_num)
          puts "requirement_met #{requirement_met}"
        else
          puts "file_executes: false"
        end
      end
    end
  end
end
