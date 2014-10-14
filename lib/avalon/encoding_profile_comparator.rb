module Avalon
  class EncodingProfileComparator
   
    EXPECTED_PROFILES = {
     'high' => {bitrate: '4000000.0', height: '780', codec: 'AVC'},
     'medium' => {bitrate: '2000000.0', height: '480', codec: 'AVC'},
     'low' => {bitrate: '1000000.0', height: '360', codec: 'AVC'}
    }
 
    def self.find_profiles()
      Derivative.find_each({}, {batch_size: 10}) do |d|
        if !EncodingProfileComparator(d).valid_profile?
          puts "\nFound invalid derivative:"
          puts d.descMetadata.pid
          puts d.encoding.quality.first
          puts d.encoding.video.video_bitrate.first
          puts d.encoding.video.resolution.first
          puts d.encoding.video.video_codec.first
        end
      end
    end

    def initialize(derivative)
      raise ArgumentError, "Can only compare video files" if !derivative.masterfile.is_video?
      raise ArgumentError, "Cannot compare skip-transcoded files" if derivative.masterfile.workflow_name == 'avalon-skip-transcoding'
      @derivative = derivative
      @profile = EXPECTED_PROFILES[derivative.encoding.quality.first]
      raise ArgumentError, "#{derivative.pid} does not have a known profile" if @profile.nil?
    end

    def valid_profile?
      valid_bitrate? && valid_resolution? && valid_codec?
    end

    def valid_bitrate?
      deviation = @derivative.encoding.video.video_bitrate.first.to_f / @profile[:bitrate].to_f
      0.9 < deviation && deviation < 1.1
    end

    def valid_resolution?
      height = @derivative.encoding.video.resolution.first.split('x')[1]
      height == @profile[:height]
    end

    def valid_codec?
      codec = @derivative.encoding.video.video_codec.first
      codec == @profile[:codec]
    end
  end 
end
