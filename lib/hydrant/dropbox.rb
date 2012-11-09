require 'digest/md5'

class Dropbox
  attr_reader :base_directory 
  
  def initialize(root)
    @base_directory = root
  end

  # Returns a list of files that have MD5 hashes
  def all 
    return nil if @base_directory.blank? or not Dir.exists?(@base_directory)
    contents = Dir.entries @base_directory
    files = Array.new 
    contents.each do |path| 
      full_path = @base_directory + path

      if File.file?( full_path ) && File.extname( path ) == ".complete"
        media_path = File.join(@base_directory, File.basename(path, ".complete"))
        if File.file?( media_path )
          info = Mediainfo.new media_path
          media_type = case 
            when info.video?
              "video"
            when info.audio? 
              "audio"
            else
              "unknown"
            end

          file = {id: Digest::MD5.hexdigest(media_path)[1..5],
                  qualified_path: media_path,
                  name: File.basename(media_path),
                  size: File.size(media_path),
                  media_type: media_type}
          files << file
        end
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
end
