# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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
  factory :media_object do
    title { Faker::Lorem.sentence }
    creator { [FactoryBot.create(:user).user_key] }
    date_issued { Time.zone.today.edtf.to_s }

    # trait :with_collection do
      collection { FactoryBot.create(:collection) }
      governing_policies { [collection] }
    # end

    factory :published_media_object do
      # with_collection
      avalon_publisher { 'publisher' }

      factory :fully_searchable_media_object do
        # with_collection
        visibility { 'public' }
        abstract { Faker::Lorem.paragraph }
        contributor { [Faker::Name.name] }
        date_created { Time.zone.today.edtf.to_s }
        publisher { [Faker::Lorem.word] }
        genre { [Faker::Lorem.word] }
        topical_subject { [Faker::Lorem.word] }
        temporal_subject { [Faker::Lorem.word] }
        geographic_subject { [Faker::Address.country] }
        physical_description { [Faker::Lorem.word] }
        table_of_contents { [Faker::Lorem.paragraph] }
        note { [{ note: Faker::Lorem.paragraph, type: 'general' }] }
        other_identifier { [{ id: Faker::Lorem.word, source: 'local' }] }
        language { ['eng'] }
        related_item_url { [{ url: Faker::Internet.url, label: Faker::Lorem.sentence }]}
        bibliographic_id { { id: Faker::Lorem.word, source: 'local' } }
        comment { ['MO comment'] }
        rights_statement { ['http://rightsstatements.org/vocab/InC-EDU/1.0/'] }
        # after(:create) do |mo|
        #   mo.update_datastream(:descMetadata, {
        #     note: {note[Faker::Lorem.paragraph],
        #     note_type: ['general'],
        #     other_identifier: [Faker::Lorem.word],
        #     other_identifier_type: ['local'],
        #     language: ['eng']
        #   })
        #  mo.save
        # end
      end
    end
    trait :with_master_file do
      after(:create) do |mo|
        mf = FactoryBot.create(:master_file)
        mf.media_object = mo
        mf.save
        # mo.ordered_master_files += [mf]
        mo.save
      end
    end
    trait :with_completed_workflow do
      after(:create) do |mo|
        mo.workflow.last_completed_step = [HYDRANT_STEPS.last.step]
        mo.save
      end
    end
  end
end
