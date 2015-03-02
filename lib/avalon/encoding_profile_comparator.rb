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

module Avalon
  class EncodingProfileComparator
   
    EXPECTED_PROFILES = {
     'high' => {video_bitrate: '2000000.0', audio_bitrate: '192000.0', height: '720', codec: 'AVC'},
     'medium' => {video_bitrate: '1000000.0', audio_bitrate: '128000.0', height: '480', codec: 'AVC'},
     'low' => {video_bitrate: '500000.0', audio_bitrate: '128000.0', height: '360', codec: 'AVC'}
    }
 
    def self.find_invalid_profiles()
      derivatives_to_reencode = []
      Derivative.find_each({}, {batch_size: 10}) do |d|
        epc = EncodingProfileComparator.new(d) rescue nil
        next if epc.nil?
        derivatives_to_reencode << d if !epc.valid_profile?
      end
      puts "Found #{derivatives_to_reencode.size} #{"item".pluralize(derivatives_to_reencode.size)} that do not match the expected profiles:"
      derivatives_to_reencode.each {|d| puts "#{d.pid}: #{d.errors.full_messages.join(',')}"}
    end

    def initialize(derivative)
      raise ArgumentError, "Can only compare video files" if !derivative.masterfile.is_video?
      raise ArgumentError, "Cannot compare skip-transcoded files" if derivative.masterfile.workflow_name == 'avalon-skip-transcoding'
      @derivative = derivative
      @profile = EXPECTED_PROFILES[derivative.encoding.quality.first]
      raise ArgumentError, "#{derivative.pid} does not have a known profile" if @profile.nil?
    end

    def valid_profile?
      valid_video_bitrate? && valid_resolution? && valid_codec? #&& valid_audio_bitrate?
    end

    def valid_video_bitrate?
      deviation = @derivative.encoding.video.video_bitrate.first.to_f / @profile[:video_bitrate].to_f
      valid = 0.9 < deviation && deviation < 1.1
      @derivative.errors.add(:video_bitrate, "is not within 10% of expected bitrate of #{@profile[:video_bitrate]}") unless valid
      valid
    end

    def valid_audio_bitrate?
      deviation = @derivative.encoding.audio.audio_bitrate.first.to_f / @profile[:audio_bitrate].to_f
      valid = 0.9 < deviation && deviation < 1.1
      @derivative.errors.add(:audio_bitrate, "is not within 10% of expected bitrate of #{@profile[:audio_bitrate]}") unless valid
      valid
    end

    def valid_resolution?
      height = @derivative.encoding.video.resolution.first.split('x')[1]
      valid = height == @profile[:height]
      @derivative.errors.add(:height, "is not the expected height of #{@profile[:height]}") unless valid
      valid
    end

    def valid_codec?
      codec = @derivative.encoding.video.video_codec.first
      valid = codec == @profile[:codec]
      @derivative.errors.add(:codec, "is not the expected codec of #{@profile[:codec]}") unless valid
      valid
    end
  end 
end
