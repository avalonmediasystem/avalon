# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

require 'rails_helper'

describe 'search', type: :request do
  describe 'subject links' do
    let!(:media_object) { FactoryBot.create(:fully_searchable_media_object, subject: ['both/and']) }

    it 'searches and finds the item' do
      get "/media_objects/#{media_object.id}/manifest.json"
      manifest_json = JSON.parse(response.body)
      subject_links = manifest_json["metadata"].find {|hash| hash["label"]["none"] == ["Subject"] }["value"]["none"]
      link = subject_links.first.match(/href="(.*)"/)[1]
      get link
      expect(response.body).to include(media_object.id)
    end
  end
end
