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

class ElasticTranscoderEncode < WatchedEncode
  self.engine_adapter = :elastic_transcoder

  before_create prepend: true do |encode|
    encode.options.merge!(pipeline_id: Settings.encoding.pipeline,
                          masterfile_bucket: Settings.encoding.masterfile_bucket,
                          outputs: elastic_transcoder_outputs(encode.options, encode.input.url))
  end

  private

    def elastic_transcoder_outputs(options, input)
      file_name = File.basename(Addressable::URI.parse(input).path, '.*').gsub(URI::UNSAFE, '_')
      et = Avalon::ElasticTranscoder.instance

      case options[:preset]
      when 'fullaudio'
        [{ key: "quality-medium/#{file_name}.mp4", preset_id: et.find_preset('mp4', :audio, :medium).id },
         { key: "quality-high/#{file_name}.mp4", preset_id: et.find_preset('mp4', :audio, :high).id }]
      when 'avalon'
        [{ key: "quality-low/#{file_name}.mp4", preset_id: et.find_preset('mp4', :video, :low).id },
         { key: "quality-medium/#{file_name}.mp4", preset_id: et.find_preset('mp4', :video, :medium).id },
         { key: "quality-high/#{file_name}.mp4", preset_id: et.find_preset('mp4', :video, :high).id }]
      else
        []
      end
    end
end
