require 'digest/md5'
module Hydrant
  class Dropbox
    attr_reader :base_directory 
    
    def initialize(root)
      @base_directory = root
    end

    # Returns available files in the dropbox
    def all 
      return nil if @base_directory.blank? or not Dir.exists?(@base_directory)
      contents = Dir.entries @base_directory
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
        full_path = @base_directory + path
        if File.file?( full_path ) && 
          File.extname( path ) != ".md5" && 
          id == Digest::MD5.hexdigest(full_path).to_s[1..5]
          return full_path 
        end
      end

      return nil
    end
    
    # Gets completed, uningested batch packages
    def find_new_packages()
      Hydrant::Batch::Package.locate(@base_directory)
    end

  #  protected
    def find_open_files(files)
      Hydrant::Batch.find_open_files(files, @base_directory)
    end
  end
end