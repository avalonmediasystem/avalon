# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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
    class Error < ::Exception; end
    class IncompletePackageError < Error; end

    def self.find_open_files(files, base_directory = '.')
      args = files.collect { |p| %{"#{p}"} }.join(' ')
      Dir.chdir(base_directory) do
        result = []
        begin
          Timeout.timeout(5) do
            status = `/usr/sbin/lsof -Fcpan0 #{args}`
            statuses = status.split(/[\u0000\n]+/)
            statuses.in_groups_of(4) do |group|
              file_status = Hash[group.compact.collect { |s| [s[0].to_sym,s[1..-1]] }]
              if file_status.has_key?(:n) and File.file?(file_status[:n]) and
                (file_status[:a] =~ /w/ or file_status[:c] == 'scp')
                  result << file_status[:n]
              end
            end
          end
        rescue Errno::ENOENT
          # lsof doesn't exist so bail
          Rails.logger.warn('lsof missing; continuing without open file checking')
        rescue Timeout::Error
          # lsof didn't return so bail
          Rails.logger.warn('lsof blocking; continuing without open file checking')
        end
        result
      end
    end

  end
end
