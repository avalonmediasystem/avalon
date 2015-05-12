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
  factory :collection, class: Admin::Collection do
    sequence(:name) {|n| "Collection #{n}" }
    unit {"University Archives"}
    description {Faker::Lorem.sentence}
    managers {[FactoryGirl.create(:manager).username]}
    editors {[FactoryGirl.create(:user).username]}
    depositors {[FactoryGirl.create(:user).username]}
    media_objects {[]}

    transient { items 0 }
    after(:create) do |c, env|
      1.upto(env.items) { FactoryGirl.create(:media_object, collection: c) }
    end
  end
end
