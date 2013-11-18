require 'pathname'

module FileLocator
  class << self
    def absolute_location(file_location)
      mount_map.each_pair do |path,mount|
        if file_location.start_with? path
          relative_path = Pathname.new(file_location)
          base_path = Pathname.new(path)
          return File.join(mount,relative_path.relative_path_from(base_path))
        end
      end
      return "file://#{file_location}"
    end

    def mount_map
      fstypes = {
      # type    =>  url_scheme
        'cifs'  => 'cifs',
        'nfs'   => 'nfs',
        'smbfs' => 'smb'
      }
      Hash[
        `mount`.split(/\n/).collect { |l|
          (loc, mount, type) = l.scan(/^(.+) on (.+?) (?:type |\()([[:alnum:]]+)/).flatten
          if fstypes.keys.include?(type)
            loc = "#{fstypes[type]}://#{loc.split(/@/).last.sub(/^\/+/,'').sub(/:/,'')}"
            [File.join(mount,''), loc]
          end
        }.compact.sort { |a,b| b[0].length <=> a[0].length }
      ]
    end
  end
end
