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

# frozen_string_literal: true

FactoryBot.define do
  factory :encode_record, class: ::ActiveEncode::EncodeRecord do
    sequence(:global_id) { |n| "app://ActiveEncode/Encode/#{n}" }
    state { "running" }
    adapter { "ffmpeg" }
    sequence(:title) { |n| "Title #{999 - n}" }
    sequence(:display_title) { |n| "Title #{999 - n}" }
    raw_object { "{\"input\":{\"url\":\"file:///Users/cjcolvar/Documents/Code/samvera/active_encode/spec/fixtures/fireworks.mp4\",\"width\":960.0,\"height\":540.0,\"frame_rate\":29.671,\"duration\":6024,\"file_size\":1629578,\"audio_codec\":\"mp4a-40-2\",\"video_codec\":\"avc1\",\"audio_bitrate\":69737,\"video_bitrate\":2092780,\"created_at\":\"2018-12-17T16:54:50.401-05:00\",\"updated_at\":\"2018-12-17T16:54:50.401-05:00\",\"id\":\"8156\"},\"options\":{},\"id\":\"35efa965-ec51-409d-9495-2ae9669adbcc\",\"output\":[{\"url\":\"file:///Users/cjcolvar/Documents/Code/samvera/active_encode/.internal_test_app/encodes/35efa965-ec51-409d-9495-2ae9669adbcc/outputs/fireworks-low.mp4\",\"label\":\"low\",\"id\":\"8156-low\",\"created_at\":\"2018-12-17T16:54:50.401-05:00\",\"updated_at\":\"2018-12-17T16:54:59.169-05:00\",\"width\":640.0,\"height\":480.0,\"frame_rate\":29.671,\"duration\":6038,\"file_size\":905987,\"audio_codec\":\"mp4a-40-2\",\"video_codec\":\"avc1\",\"audio_bitrate\":72000,\"video_bitrate\":1126859},{\"url\":\"file:///Users/cjcolvar/Documents/Code/samvera/active_encode/.internal_test_app/encodes/35efa965-ec51-409d-9495-2ae9669adbcc/outputs/fireworks-high.mp4\",\"label\":\"high\",\"id\":\"8156-high\",\"created_at\":\"2018-12-17T16:54:50.401-05:00\",\"updated_at\":\"2018-12-17T16:54:59.169-05:00\",\"width\":1280.0,\"height\":720.0,\"frame_rate\":29.671,\"duration\":6038,\"file_size\":2102027,\"audio_codec\":\"mp4a-40-2\",\"video_codec\":\"avc1\",\"audio_bitrate\":72000,\"video_bitrate\":2721866}],\"state\":\"completed\",\"errors\":[],\"created_at\":\"2018-12-17T16:54:50.401-05:00\",\"updated_at\":\"2018-12-17T16:54:59.169-05:00\",\"current_operations\":[],\"percent_complete\":100,\"global_id\":{\"uri\":\"gid://ActiveEncode/Encode/35efa965-ec51-409d-9495-2ae9669adbcc\"}}" }
    create_options { "{\"outputs\":[{\"label\":\"high\",\"extension\":\"mp4\",\"ffmpeg_opt\":\"-ac 2 -ab 192k -ar 44100 -acodec aac\"},{\"label\":\"medium\",\"extension\":\"mp4\",\"ffmpeg_opt\":\"-ac 2 -ab 128k -ar 44100 -acodec aac\"}],\"master_file_id\":\"6q182k13s\",\"media_object_id\":\"6q182k12h\",\"local_streaming\":true}" }
    progress { 75 }
  end
end
