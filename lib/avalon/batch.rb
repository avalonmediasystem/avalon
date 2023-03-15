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

require 'active_support/core_ext/array'
require "avalon/batch/entry"
require "avalon/batch/ingest"
require "avalon/batch/manifest"
require "avalon/batch/file_manifest"
require "avalon/batch/s3_manifest"
require "avalon/batch/package"
require "timeout"

module Avalon
  module Batch
    # Breaking the next method up further would only obscure logic
    # rubocop:disable Metrics/MethodLength
    def self.find_open_files(files, base_directory = '.')
      found_files = []
      lsof = find_lsof
      unless lsof
        Rails.logger.warn('lsof missing; continuing without open file checking')
        return found_files
      end

      args = files.collect { |p| %("#{p}") }.join(' ')
      Dir.chdir(base_directory) do
        begin
          Timeout.timeout(5) do
            output = `#{lsof} -Fcpan0 #{args}`
            found_files = extract_files_from_lsof_output(output)
          end
        rescue Timeout::Error
          Rails.logger.warn('lsof blocking; continuing without open file checking')
        end
      end
      found_files
    end
    # rubocop:enable Metrics/MethodLength

    def self.find_lsof
      (['/usr/sbin', '/usr/bin'] + ENV['PATH'].split(File::PATH_SEPARATOR))
        .map { |path| "#{path}/lsof" }.find do |executable|
        File.executable?(executable)
      end
    end

    def self.extract_files_from_lsof_output(output)
      found_files = []
      statuses = output.split(/[\u0000\n]+/)
      statuses.in_groups_of(4) do |group|
        file_status = Hash[group.compact.collect { |s| [s[0].to_sym, s[1..-1]] }]
        if file_status.key?(:n) && File.file?(file_status[:n]) &&
           (file_status[:a] =~ /w/ || file_status[:c] == 'scp')
          found_files << file_status[:n]
        end
      end
      found_files
    end
  end
end
