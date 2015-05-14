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
  factory :media_object do
    title {Faker::Lorem.sentence}
    creator {[FactoryGirl.create(:user).username]}
    date_issued {"#{Date.today.edtf}"}
    collection {FactoryGirl.create(:collection)}

    factory :published_media_object do
      avalon_publisher {'publisher'}

      factory :fully_searchable_media_object do
        visibility {'public'}
        abstract {Faker::Lorem.paragraph}
        contributor {[Faker::Name.name]}
        date_created {"#{Date.today.edtf}"}
        publisher {[Faker::Lorem.word]}
        genre {[Faker::Lorem.word]}
        topical_subject {[Faker::Lorem.word]}
        temporal_subject {[Faker::Lorem.word]}
        geographic_subject {[Faker::Address.country]}
        physical_description {Faker::Lorem.word}
        table_of_contents {[Faker::Lorem.paragraph]}
        after(:create) do |mo|
          mo.update_datastream(:descMetadata, {
            note: [Faker::Lorem.paragraph], 
            note_type: ['general'], 
            other_identifier: [Faker::Lorem.word],
            other_identifier_type: ['local'],
            language: ['eng']
          })
          mo.save
        end
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
    creator ['RSpec']
    date_issued '#{Date.today.edtf}'
    abstract 'A bare bones test record with only required fields completed'
  end
  
  factory :single_entry, class: MediaObject do
    title 'Single contributor'
    creator ['RSpec']
    date_issued '#{Date.today.edtf}'
    abstract 'A record with only a single contributor and publisher'
    
    contributor 'RSpec helper'
    publisher 'Ruby on Rails'
    subject 'Programming'
  end
  
  factory :multiple_entries, class: MediaObject do
    title 'Multiple contributors'
    creator ['RSpec']
    date_issued '#{Date.today.edtf}'
    abstract 'A record with multiple contributors, publishers, and search terms'
    
    contributor ['Chris Colvard', 'Nathan Rogers', 'Phuong Dinh']
    publisher ['Mark Notess', 'Jon Dunn', 'Stu Baker']
    subject ['Programming', 'Ruby on Rails']
  end
end
