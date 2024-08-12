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

module Avalon
  class FFprobe
    # media_path should be the output of `FileLocator.new(file_location).location`
    def initialize(media_path)
      @json_output = JSON.parse(`ffprobe -i "#{media_path}" -v quiet -show_format -show_streams -count_packets -of json`).deep_symbolize_keys
      @video_stream = @json_output[:streams].select { |stream| stream[:codec_type] == 'video' }.first
    end

    def video?
      # ffprobe treats plain text files as ANSI or ASCII art. This sets the codec type to video
      # but leaves display aspect ratio `nil`. If display_aspect_ratio is nil, return false.
      # ffprobe treats image files as a single frame video. This sets the codec type to video
      # but the packet/frame count will equal 1. If packet count equals 1, return false.
      return true if @video_stream && @video_stream[:display_aspect_ratio] && @video_stream[:nb_read_packets].to_i > 1

      false
    end

    def audio?
      @json_output[:streams].any? { |stream| stream[:codec_type] == 'audio' }
    end

    def duration
      # ffprobe return duration as seconds. Existing Avalon logic expects milliseconds.
      (@json_output[:format][:duration].to_f * 1000).to_i
    end

    def display_aspect_ratio
      @video_stream[:display_aspect_ratio] if video?
    end

    def original_frame_size
      "#{@video_stream[:width]}x#{@video_stream[:height]}" if video?
    end
  end
end