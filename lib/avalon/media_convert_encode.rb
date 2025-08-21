# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

require 'avalon/elastic_transcoder'

class MediaConvertEncode < WatchedEncode
  self.engine_adapter = :media_convert
  self.engine_adapter.role = Settings.encoding.mediaconvert_role
  self.engine_adapter.output_bucket = Settings.encoding.derivative_bucket

  #self.engine_adapter.setup!
  self.engine_adapter.direct_output_lookup = true

  before_create prepend: true do |encode|
    encode.options.merge!(use_original_url: true,
                          output_type: :file,
                          outputs: mediaconvert_outputs(encode.options))
  end

  private

    def mediaconvert_outputs(options)
      case options[:preset]
      when 'fullaudio'
        [{ modifier: "quality-medium", preset: 'audio_medium' },
        { modifier: "quality-high", preset: 'audio_high' }]
      when 'avalon'
        [{ modifier: "quality-low", preset: 'video_low' },
        { modifier: "quality-medium", preset: 'video_medium' },
        { modifier: "quality-high", preset: 'video_high' }]
      else
        []
      end
    end
end
