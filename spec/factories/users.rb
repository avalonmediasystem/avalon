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
  factory :user do
    email { Faker::Internet.unique.email }
    username { Faker::Internet.unique.username }
    password { 'testing123' }

    factory :administrator, aliases: [:admin] do
      after(:create) do |user|
        begin
          Avalon::RoleControls.add_user_role(user.user_key, 'administrator')
        rescue
        end
      end
    end
    factory :unit_administrator, aliases: [:unit_admin] do
      after(:create) do |user|
        begin
          Avalon::RoleControls.add_user_role(user.user_key, 'unit_administrator')
        rescue
        end
      end
    end
    factory :manager do
      after(:create) do |user|
        begin
          Avalon::RoleControls.add_user_role(user.user_key, 'manager')
        rescue
        end
      end
    end
    factory :group_manager do
      after(:create) do |user|
        begin
          Avalon::RoleControls.add_user_role(user.user_key, 'group_manager')
        rescue
        end
      end
    end
    factory :user_lti do
    end

    trait :with_identity do
      after(:create) do |user|
        Identity.create!(email: user.email, password: user.password)
      end
    end
  end

  factory :cataloger, class: User  do
    sequence(:username) {|n| "archivist#{n}" }
    sequence(:email)    {|n| "archivist#{n}@example.com" }
    password            { 'testing123' }
  end

  factory :content_provider, class: User  do
    sequence(:username) {|n| "archivist#{n}" }
    sequence(:email)    {|n| "archivist#{n}@example.com" }
    password            { 'testing123' }
    after(:create) do |user|
      begin
        Avalon::RoleControls.add_user_role(user.user_key, 'manager')
      rescue
      end
    end
  end

  factory :student, class: User  do
    sequence(:username) {|n| "ann.e.student#{n}" }
    sequence(:email)    {|n| "student#{n}@example.com" }
    password            { 'testing123' }
  end

  factory :public, class: User  do
    sequence(:username) {|n| "average.joe#{n}" }
    sequence(:email)    {|n| "average.joe#{n}@example.com" }
    password            { 'testing123' }
  end
end
