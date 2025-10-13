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

FactoryBot.define do
  factory :unit, class: Admin::Unit do
    sequence(:name) { |n| "Unit #{n}" }
    description { Faker::Lorem.sentence }
    contact_email { Faker::Internet.email }
    website_label { Faker::Lorem.words.join(' ') }
    website_url { Faker::Internet.url }
    unit_admins { [FactoryBot.create(:unit_admin).user_key] }
    managers { [FactoryBot.create(:manager).user_key] }
    editors { [FactoryBot.create(:user).user_key] }
    depositors { [FactoryBot.create(:user).user_key] }
    collections { [] }

    transient { items { 0 } }
    after(:create) do |u, env|
      1.upto(env.items) { FactoryBot.create(:collection, unit: u) }
      u.reload
    end

    trait :with_poster do
      after(:create) do |unit|
        unit.poster.mime_type = 'image/png'
        unit.poster.content = 'fake image content'
        unit.save
      end
    end
  end
end
