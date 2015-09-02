# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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
    mediaobject {FactoryGirl.create(:media_object)}

    factory :master_file_with_derivative do
      workflow_name 'avalon'
      status_code 'COMPLETED'
      after(:create) do |mf|
        mf.derivatives += [FactoryGirl.create(:derivative)]
        mf.save
      end
    end
    factory :master_file_with_thumbnail do
      after(:create) do |mf|
        mf.thumbnail.mimeType = 'image/jpeg'
        mf.thumbnail.content = 'fake image content'
        mf.save
      end
    end
  end
end
