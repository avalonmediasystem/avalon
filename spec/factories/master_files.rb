# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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
    status_code {Faker::Lorem.word}
    file_location {'/path/to/video.mp4'}
    percent_complete {"#{rand(100)}"}
    after(:create) do |mf|
      mf.mediaobject = FactoryGirl.create(:media_object)
      mf.save
    end
    factory :master_file_with_derivative do
      after(:create) do |mf|
        mf.derivatives += [FactoryGirl.create(:derivative)]
        mf.save
      end
    end
  end
end
