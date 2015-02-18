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
  factory :user do
    email { Faker::Internet.email }
    username { [Faker::Name.last_name.gsub("'",""),Faker::Name.first_name.gsub("'","")].join('.').downcase }

    factory :administrator do
      after(:create) do |user|
        begin
          RoleControls.add_user_role(user.username, 'administrator')
        rescue
        end
      end 
    end
    factory :manager do
      after(:create) do |user|
        begin
          RoleControls.add_user_role(user.username, 'manager')
        rescue
        end
      end 
    end
    factory :user_lti do
    end
  end 

  factory :cataloger, class: User  do
    sequence(:username) {|n| "archivist#{n}" }
    sequence(:email)    {|n| "archivist#{n}@example.com" }
  end

  factory :policy_editor, class: User  do
    sequence(:username) {|n| "archivist#{n}" }
    sequence(:email)    {|n| "archivist#{n}@example.com" }
    after(:create) do |user|
      begin
        RoleControls.add_user_role(user.username, 'group_manager')
      rescue
      end
    end
  end

  factory :content_provider, class: User  do
    sequence(:username) {|n| "archivist#{n}" }
    sequence(:email) {|n| "archivist#{n}@example.com" }
    after(:create) do |user|
      begin
        RoleControls.add_user_role(user.username, 'manager')
      rescue
      end
    end 
  end

  factory :student, class: User  do
    sequence(:username) {|n| "ann.e.student#{n}" }
    sequence(:email) {|n| "student#{n}@example.com" }
  end

  factory :public, class: User  do
    sequence(:username) {|n| "average.joe#{n}" }
    sequence(:email) {|n| "average.joe#{n}@example.com" }
  end
end
