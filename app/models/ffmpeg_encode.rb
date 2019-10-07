# frozen_string_literal: true
# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

class FfmpegEncode < WatchedEncode
  before_create prepend: true do |encode|
    encode.options.merge!(outputs: ffmpeg_outputs(encode.options))
  end

  private

    def ffmpeg_outputs(options)
      case options[:preset]
      when 'fullaudio'
        [{ label: 'high', extension: 'mp4', ffmpeg_opt: "-ac 2 -ab 192k -ar 44100 -acodec aac" },
         { label: 'medium', extension: 'mp4', ffmpeg_opt: "-ac 2 -ab 128k -ar 44100 -acodec aac" }]
      when 'avalon'
        [{ label: 'high', extension: 'mp4', ffmpeg_opt: "-s 1920x1080 -g 30 -b:v 800k -ac 2 -ab 192k -ar 44100 -vcodec libx264 -acodec aac" },
         { label: 'medium', extension: 'mp4', ffmpeg_opt: "-s 1280x720 -g 30 -b:v 500k -ac 2 -ab 128k -ar 44100 -vcodec libx264 -acodec aac" },
         { label: 'low', extension: 'mp4', ffmpeg_opt: "-s 720x360 -g 30 -b:v 300k -ac 2 -ab 96k -ar 44100 -vcodec libx264 -acodec aac" }]
      else
        []
      end
    end
end
