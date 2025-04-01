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
  factory :batch_entries do
    association :batch_registries
    complete { false }
    error { false }
    current_status { 'registered' }
    error_message {}
    media_object_pid { 'kfd39dnw' }
    payload { "{\"publish\":false,\"hidden\":false,\"fields\":{\"title\":[\"Dolorum\"],\"creator\":[\"Carroll, Nora\"],\"date_issued\":[\"2012\"],\"other_identifier\":[\"ABC123\"],\"other_identifier_type\":[\"local\"],\"related_item_url\":[\"http://www.example.com/text.pdf\"],\"related_item_label\":[\"Example Item PDF\"],\"rights_statement\":[\"http://rightsstatements.org/vocab/InC/1.0/\"],\"terms_of_use\":[\"Terms of Use Language\"],\"language\":[\"English\"],\"physical_description\":[\"16mm Reel\"],\"note\":[\"This is a test general note\"],\"note_type\":[\"general\"],\"abstract\":[\"Test abstract\"],\"statement_of_responsibility\":[\"Test Statement of Responsibility\"]},\"files\":[{\"file\":\"spec/fixtures/jazz-performance.mp3\",\"offset\":\"00:00:00.500\",\"label\":\"Quis quo\",\"date_digitized\":\"2015-10-30\"}],\"position\":3,\"user_key\":\"frances.dickens@reichel.com\",\"collection\":\"#{batch_registries.collection}\"}" }
  end
end
