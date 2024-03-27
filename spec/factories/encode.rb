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
  factory :encode, class: ActiveEncode::Base do
    id { SecureRandom.uuid }
    errors {}
    state { :running }
    percent_complete { 0 }
    current_operations { ['Queued'] }

    initialize_with { new('file://path/to/input.mp4') }

    trait :in_progress do
      state { :running }
      percent_complete { 50.5 }
      current_operations { ['encoding'] }
      input { FactoryBot.build(:encode_output) }
    end
      
    trait :succeeded do
      state { :completed }
      percent_complete { 100 }
      current_operations { ['DONE'] }
      input { FactoryBot.build(:encode_output) }
      output { [ FactoryBot.build(:encode_output) ] }
    end

    trait :failed do
      state { :failed }
      percent_complete { 50.5 }
      current_operations { ['FAILED'] }
      input { FactoryBot.build(:encode_output) }
      errors { ['Out of disk space.'] }
    end
  end

  factory :encode_input, class: ActiveEncode::Input do
    id { SecureRandom.uuid }
    label { 'quality-high' }
    url { 'file://path/to/output.mp4' }
    duration { '21575.0' }
    audio_bitrate { '163842.0' }
    audio_codec { 'AAC' }
    video_bitrate { '4000000.0' }
    video_codec { 'AVC' }
    width { '1024' }
    height { '768' }
  end

  factory :encode_output, class: ActiveEncode::Output do
    id { SecureRandom.uuid }
    label { 'quality-high' }
    url { 'file://path/to/output.mp4' }
    duration { '21575.0' }
    audio_bitrate { '163842.0' }
    audio_codec { 'AAC' }
    video_bitrate { '4000000.0' }
    video_codec { 'AVC' }
    width { '1024' }
    height { '768' }
  end
end
