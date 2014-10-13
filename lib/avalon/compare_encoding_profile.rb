module Avalon
  class CompareEncodingProfile
    attr_accessor :path
    
    def initialize(path)
      self.path = path
    end

    def self.find_profiles()
      Derivative.find_each({}, {batch_size: 10}) do |d|
        if d.masterfile.is_video? && d.masterfile.workflow_name != 'avalon-skip-transcoding'
          puts d.descMetadata.pid
          puts d.encoding.quality.first
          puts d.encoding.video.video_bitrate.first
          puts d.encoding.video.resolution.first
          puts d.encoding.video.video_codec.first
        end
      end
    end

  end 
end
