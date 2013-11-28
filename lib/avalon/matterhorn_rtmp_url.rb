require 'uri'

module Avalon
  class MatterhornRtmpUrl < Struct.new(:application, :prefix, :media_id, :stream_id, :filename, :extension)

    REGEX = %r{^
      /(?<application>.+)        # application (avalon)
      /(?:(?<prefix>.+):)?       # prefix      (mp4:)
      (?<media_id>[^\/]+)        # media_id    (98285a5b-603a-4a14-acc0-20e37a3514bb)
      /(?<stream_id>[^\/]+)      # stream_id   (b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3)
      /(?<filename>.+?)          # filename    (MVI_0057)
      (?:\.(?<extension>.+))?$   # extension   (mp4)
    }x

    def initialize(hash)
      super(*members.map {|member| hash[member]})
    end

    def self.parse(url_string)
      # Example input: /avalon/mp4:98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4

      uri = URI.parse(url_string)
      match_data = REGEX.match(uri.path)
      MatterhornRtmpUrl.new match_data    
    end

    alias_method :'_binding', :'binding'
    def binding
      _binding
    end

    def to_path
      File.join(media_id, stream_id, "#{filename}.#{extension||prefix}")
    end
  end
end
