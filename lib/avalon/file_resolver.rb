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

require 'pathname'
require 'uri'

module Avalon
  class FileResolver
    attr_reader :mounts

    def initialize
      @mounts = %x[mount].split(/\n/)
    end

    def overrides
      if @overrides.nil?
        path = Rails.root.join('config','mounts.yml')
        if File.file? path
          @overrides = YAML.load(File.read(path))
        else
          @overrides = {}
        end
      end
      @overrides
    end

    def path_to(file_location)
      url = Addressable::URI.parse(file_location)
      if url.scheme.nil? or url.scheme == 'file'
        mount_map.each_pair do |path,mount|
          if file_location.start_with? path
            relative_path = Pathname.new(file_location)
            base_path = Pathname.new(path)
            return File.join(mount,relative_path.relative_path_from(base_path))
          end
        end
        return "file://#{file_location}"
      else
        return url.to_s
      end
    end

    def mount_map
      fstypes = ['nfs','cifs','smbfs']
      @mount_map ||= Hash[
        mounts.collect { |l|
          (loc, mount, type) = l.scan(/^(.+) on (.+?) (?:type |\()([[:alnum:]]+)/).flatten
          if fstypes.include?(type)
            scheme = 'file'
            case type
            when 'nfs'
              loc = File.join(*(loc.split(/:\//,2)))
              scheme = 'nfs'
            when 'smbfs','cifs'
              loc = loc.split(/@/).last.sub(%r{^//},'')
              scheme = type == 'smbfs' ? 'smb' : 'cifs'
            end
            loc = "#{scheme}://#{loc}"
            [File.join(mount,''), loc]
          end
        }.compact.sort { |a,b| b[0].length <=> a[0].length }
      ].merge(overrides)
    end
  end
end
