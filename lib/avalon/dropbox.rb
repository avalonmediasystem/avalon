# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'digest/md5'
module Avalon
  class Dropbox
    attr_reader :base_directory, :collection 
    
    def initialize(root, collection)
      @base_directory = root
      @collection = collection
    end

    # Returns available files in the dropbox
    def all 
      return nil if @base_directory.blank? or not Dir.exists?(@base_directory)
      contents = Dir.entries(@base_directory).reject { |fn| fn.start_with?('.') }
      open_files = find_open_files(contents)
      files = []
      contents.each do |path| 
        media_type = Rack::Mime.mime_type(File.extname(path))
        if media_type =~ %r{^(audio|video)/}
          media_path = File.join(@base_directory, path)
          available = !open_files.include?(path)
          files << {
            id: Digest::MD5.hexdigest(media_path)[1..5],
            qualified_path: media_path,
            name: File.basename(media_path),
            size: (available ? File.size(media_path) : 'Loading...'),
            modified: File.mtime(media_path),
            media_type: media_type,
            available: available
          }
        end
      end

      return files
    end

    # Compares id against hash of each file's full path and return the path that matches
    # Pretty horrible, should destroy 
    def find(id)
      return nil if @base_directory.blank? or not Dir.exists?(@base_directory)

      Dir.entries(@base_directory).each do |path|
        full_path = File.join( @base_directory, path)
        if File.file?( full_path ) && 
          File.extname( path ) != ".md5" && 
          id == Digest::MD5.hexdigest(full_path).to_s[1..5]
          return full_path 
        end
      end

      return nil
    end

    def delete( filename )
      full_path = File.join( @base_directory, filename )
      begin
        File.delete full_path
        true
      rescue Exception => e
        logger.warn "Could not delete file #{filename} in #{@base_directory}: #{e}"
        false
      end
    end
    
    # Gets completed, uningested batch packages
    def find_new_packages()
      Avalon::Batch::Package.locate(@base_directory, @collection)
    end

  #  protected
    def find_open_files(files)
      Avalon::Batch.find_open_files(files, @base_directory)
    end
  end
end
