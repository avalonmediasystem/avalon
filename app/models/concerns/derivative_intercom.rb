# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

module DerivativeIntercom
  def to_ingest_api_hash
    {
      label: "quality-#{quality}", # quality-low, quality-medium, quality-high
      id: id,
      url: location_url,
      hls_url: hls_url,
      duration: duration,
      mime_type: mime_type,
      audio_bitrate: audio_bitrate,
      audio_codec: audio_codec,
      video_bitrate: video_bitrate,
      video_codec: video_codec,
      width: (resolution.present? ? resolution.split('x')[0] || nil : nil),
      height: (resolution.present? ? resolution.split('x')[1] || nil : nil),
      location: location_url,
      track_id: track_id,
      hls_track_id: hls_track_id,
      managed: false,
      derivativeFile: derivativeFile
    }
  end
end
