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

FactoryBot.define do
  factory :derivative do
    duration { "21575" }
    location_url { "6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning" }
    track_id { "track-6" }
    hls_url { "http://localhost:3000/streams/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4.m3u8" }
    hls_track_id { "track-8" }
    width { '1024' }
    height { '768' }
    quality { 'high' }
    video_codec { 'AVC' }
    video_bitrate { '4000000.0' }
    audio_codec { 'AAC' }
    audio_bitrate { '163842.0' }
    mime_type { nil }
    derivativeFile { 'file:///srv/avalon/content/6f69c008-06a4-4bad-bb60-26297f0b4c06/35bddaa0-fbb4-404f-ab76-58f22921529c/warning.mp4' }

    trait :with_master_file do
      after(:create) do |d|
        d.master_file = FactoryBot.create(:master_file)
        d.save
      end
    end
  end
end
