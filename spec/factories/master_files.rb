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
  factory :master_file do
    file_location {'/path/to/video.mp4'}
    file_format {'Moving image'}
    # original_filename { 'video.mp4' }
    # percent_complete {"#{rand(100)}"}
    workflow_name { 'avalon' }
    duration {'200000'}
    identifier { ['other identifier'] }
    display_aspect_ratio { '1.7777777777777777' }
    original_frame_size { '1024X768' }
    width { '1024' }
    height { '768' }
    date_digitized { Time.now.utc.iso8601 }

    sequence(:workflow_id)

    transient do
      status_code { :running }
    end

    after(:build) do |mf, evaluator|
      if evaluator.status_code
        FactoryBot.create(:encode_record, global_id: "gid://ActiveEncode/#{mf.encoder_class}/#{mf.workflow_id}", state: evaluator.status_code)
      end
    end

    trait :audio do
      file_format { 'Sound' }
      workflow_name { 'fullaudio' }
      display_aspect_ratio { nil }
      original_frame_size { nil }
      width { nil }
      height { nil }
    end

    trait :with_media_object do
      association :media_object #, factory: :media_object
    end

    trait :with_derivative do
      after(:create) do |mf|
        mf.derivatives += [FactoryBot.create(:derivative, quality: 'high')]
        mf.save
      end
    end
    trait :with_thumbnail do
      after(:create) do |mf|
        mf.thumbnail.mime_type = 'image/jpeg'
        mf.thumbnail.content = 'fake image content'
        mf.save
      end
    end
    trait :with_poster do
      after(:create) do |mf|
        mf.poster.mime_type = 'image/jpeg'
        mf.poster.content = 'fake image content'
        mf.save
      end
    end
    trait :with_structure do
      after(:create) do |mf|
        mf.structuralMetadata.content = File.read('spec/fixtures/structure.xml')
        mf.save
      end
    end
    trait :with_captions do
      after(:create) do |mf|
        mf.captions.content = File.read('spec/fixtures/captions.vtt')
        mf.captions.original_name = 'captions.vtt'
        mf.save
      end
    end
    trait :with_waveform do
      after(:create) do |mf|
        mf.waveform.mime_type = 'application/json'
        mf.waveform.content = File.read('spec/fixtures/waveform.json')
        mf.save
      end
    end
    trait :with_comments do
      comment { ['MF Comment 1', 'MF Comment 2'] }
    end

    factory :master_file_with_media_object_and_derivative, traits: [:with_media_object, :with_derivative]

    trait :completed_processing do
      transient do
        status_code { :completed }
      end
    end

    trait :cancelled_processing do
      transient do
        status_code { :cancelled }
      end
    end

    trait :failed_processing do
      transient do
        status_code { :failed }
      end
    end

    trait :not_processing do
      workflow_id { nil }
      transient do
        status_code { nil }
      end
    end
  end
end
