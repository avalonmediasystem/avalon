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
    attr_reader :json_output, :video_stream, :audio_stream
    # @param [String] media_path the full path to the media file
    def initialize(media_path)
      ffprobe = Settings&.ffprobe&.path || 'ffprobe'
      raw_output = `#{ffprobe} -i "#{media_path}" -v quiet -show_format -show_streams -count_frames -of json`
      # $? is a variable for the exit status of the last executed process. 
      # Success == 0, any other value means the command failed in some way.
      unless $?.exitstatus == 0
        @json_output = {}
        Rails.logger.error "File processing failed. Please ensure that FFprobe is installed and that the correct path is configured."
        return
      end
      @json_output = JSON.parse(raw_output).deep_symbolize_keys

      # Plain text files should return from ffprobe as an empty hash.
      # When the hash is not empty, the format name is 'tty' so we provide
      # a catch here just in case.
      return @json_output = {} if json_output[:format][:format_name] == 'tty'

      @video_stream = json_output[:streams].select { |stream| stream[:codec_type] == 'video' }.first
      @audio_stream = json_output[:streams].select { |stream| stream[:codec_type] == 'audio' }.first
    end

    def video?
      # ffprobe treats image files as a single frame video. This sets the codec type to video,
      # but leaves the frame count at 1. If frame count is 1, return false.
      return true if video_stream && video_stream[:nb_read_frames].to_i > 1

      false
    end

    def audio?
      return true if audio_stream

      false
    end

    def duration
      return unless video? || audio?
      # ffprobe return duration as seconds. Existing Avalon logic expects milliseconds.
      (json_output[:format][:duration].to_f * 1000).to_i
    end

    def display_aspect_ratio
      if video? && video_stream[:display_aspect_ratio].present?
        video_stream[:display_aspect_ratio]
      elsif video?
        video_stream[:width].to_f / video_stream[:height].to_f
      end
    end

    def original_frame_size
      "#{video_stream[:width]}x#{video_stream[:height]}" if video?
    end
  end
end