require 'digest/md5'

class Dropbox

  # Returns a list of files that have MD5 hashes
  def self.files_with_hash dir
    dir_contents = Dir.entries(dir)
    files = Array.new 
    dir_contents.each do |path| 
      full_path = dir + path
      if File.file?( full_path ) && File.extname( path ) == ".md5"
        media_path = dir + File.basename(path, ".md5")
        if File.file?( media_path )
          md5_file = File.open(full_path, "r")
          md5_content = md5_file.read
          md5_file.close
          
          info = Mediainfo.new media_path
          media_type = case 
            when info.video?
              "video"
            when info.audio? 
              "audio"
            else
              "unknown"
            end

          file = Hash.new
          file["id"] = Digest::MD5.hexdigest media_path
          file["md5"] = md5_content 
          file["full_path"] = media_path
          file["file_size"] = File.size media_path
          file["media_type"] = media_type
          files << file
          puts file.inspect
        end
      end
    end

    return files
  end

  # Compares id against hash of each file's full path and return the path that matches
  # Pretty horrible, should destroy 
  def find_by_id(dir, id)
    Dir.entries(dir).each do |path|
      full_path = dir + path
      if File.file?( full_path ) && File.extname( path ) != ".md5" && id == Digest::MD5.hexdigest(full_path)
        return full_path 
      end
    end

    return nil
  end
end
