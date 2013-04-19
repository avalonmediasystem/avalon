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
  factory :minimal_record, class: MediaObject do
    title 'Minimal test record'
    creator 'RSpec'
    date_issued '#{Time.now}'
    abstract 'A bare bones test record with only required fields completed'
  end
  
  factory :single_entry, class: MediaObject do
    title 'Single contributor'
    creator 'RSpec'
    date_issued '#{Time.now}'
    abstract 'A record with only a single contributor and publisher'
    
    contributor 'RSpec helper'
    publisher 'Ruby on Rails'
    subject 'Programming'
  end
  
  factory :multiple_entries, class: MediaObject do
    title 'Multiple contributors'
    creator 'RSpec'
    date_issued '#{Time.now}'
    abstract 'A record with multiple contributors, publishers, and search terms'
    
    contributor ['Chris Colvard', 'Nathan Rogers', 'Phuong Dinh']
    publisher ['Mark Notess', 'Jon Dunn', 'Stu Baker']
    subject ['Programming', 'Ruby on Rails']
  end
end
