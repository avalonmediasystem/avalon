# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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
  factory :playlist do
    user { FactoryBot.create(:user) }
    title { Faker::Lorem.word }
    comment { Faker::Lorem.sentence }
    visibility { Playlist::PRIVATE }

    trait :with_access_token do
      visibility { Playlist::PRIVATE_WITH_TOKEN }
      access_token { Faker::Lorem.characters(10) }
    end

    trait :with_playlist_item do
      items { [FactoryBot.create(:playlist_item)] }
    end
  end
end
