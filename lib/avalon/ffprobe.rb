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
    # @param [FileLocator] media_file a file locator instance for the media file
    def initialize(media_file)
      @media_file = media_file
    end

    def json_output
      return @json_output unless @json_output.nil?
      return @json_output = {} unless valid_content_type?(@media_file)
      ffprobe = Settings&.ffprobe&.path || 'ffprobe'
      raw_output = `#{ffprobe} -i "#{@media_file.location}" -v quiet -show_format -show_streams -of json`
      # $? is a variable for the exit status of the last executed process. 
      # Success == 0, any other value means the command failed in some way.
      unless $?.exitstatus == 0
        Rails.logger.error "File processing failed. Please ensure that FFprobe is installed and that the correct path is configured."
        return @json_output = {}
      end
      @json_output = JSON.parse(raw_output).deep_symbolize_keys
      @json_output
    end

    def video_stream
      return unless json_output.present?
      @video_stream ||= json_output[:streams].select { |stream| stream[:codec_type] == 'video' }.first
    end

    def audio_stream
      return unless json_output.present?
      @audio_stream ||= json_output[:streams].select { |stream| stream[:codec_type] == 'audio' }.first
    end

    def video?
      video_stream.present?
    end

    def audio?
      audio_stream.present?
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
        (video_stream[:width].to_f / video_stream[:height].to_f).to_s
      end
    end

    def original_frame_size
      "#{video_stream[:width]}x#{video_stream[:height]}" if video?
    end

    private

    def valid_content_type? media_file
      # Remove S3 credentials or other params from extension output
      extension = File.extname(media_file.location)&.gsub(/[\?#].*/, '')
      # Fall back on file extension if magic bytes fail to identify file
      content_type = Marcel::MimeType.for media_file.reader, extension: extension

      ['audio', 'video'].any? { |type| content_type.include?(type) }
    end
  end
end