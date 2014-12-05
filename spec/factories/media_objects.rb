# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
  factory :media_object do
    title {Faker::Lorem.sentence}
    creator {FactoryGirl.create(:user).username}
    date_issued {"#{Time.now}"}
    collection {FactoryGirl.create(:collection)}

    factory :published_media_object do
      avalon_publisher {'publisher'}

      factory :fully_searchable_media_object do
        visibility {'public'}
        abstract {Faker::Lorem.paragraph}
        contributor {Faker::Name.name}
        date_created {"#{Time.now}"}
        publisher {Faker::Lorem.word}
        genre {Faker::Lorem.word}
        topical_subject {Faker::Lorem.word}
        temporal_subject {Faker::Lorem.word}
        geographic_subject {Faker::Address.country}
        #language {"eng"} #Skip language because it is broken due to OM not using
                          #templates when setting values outside of #update_datastream
        physical_description {Faker::Lorem.word}
      end
    end
    factory :media_object_with_master_file do
      after(:create) do |mo|
        mf = FactoryGirl.create(:master_file)
        mf.mediaobject = mo
        mf.save
        mo.parts += [mf]
        mo.save
      end
    end
  end

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
