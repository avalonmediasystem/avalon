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

FactoryGirl.define do
  factory :master_file do
    file_location {'/path/to/video.mp4'}
    file_format {'Moving image'}
    percent_complete {"#{rand(100)}"}
    workflow_name 'avalon'
    duration {'200000'}
    identifier ['other identifier']
    display_aspect_ratio '1.7777777777777777'
    original_frame_size '1024X768'
    width '1024'
    height '768'

    trait :with_media_object do
      association :media_object #, factory: :media_object
    end

    trait :with_derivative do
      status_code 'COMPLETED'
      after(:create) do |mf|
        mf.derivatives += [FactoryGirl.create(:derivative, quality: 'high')]
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
        mf.save
      end
    end
    trait :with_comments do
      comment ['MF Comment 1', 'MF Comment 2']
    end
  end
end
