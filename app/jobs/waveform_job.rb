# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

class WaveformJob < ActiveJob::Base
  PLAYER_WIDTH_IN_PX = 1200
  FINEST_ZOOM_IN_SEC = 5
  SAMPLES_PER_FRAME = (44_100 * FINEST_ZOOM_IN_SEC) / PLAYER_WIDTH_IN_PX

  def perform(master_file_id)
    master_file = MasterFile.find(master_file_id)

    service = WaveformService.new(8, SAMPLES_PER_FRAME)
    json = service.get_waveform_json(file_uri(master_file))
    return unless json.present?

    master_file.waveform.content = json
    master_file.waveform.mime_type = 'application/json'
    master_file.save
  end

  private

    def file_uri(master_file)
      path = master_file.file_location
      return path if path.present? && File.exist?(path)

      playlist_url = playlist_url(master_file)
      if playlist_url
        SecurityHandler.secure_url(playlist_url, target: master_file.id)
      end
    end

    def playlist_url(master_file)
      quality = master_file.is_video? ? 'low' : 'medium'
      quality_details = master_file.stream_details[:stream_hls].find { |d| d[:quality] == quality }
      quality_details.present? ? quality_details[:url] : nil
    end
end
