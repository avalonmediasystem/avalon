# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

describe 'atom feed', type: :request do
  it 'returns an atom feed' do
    get '/catalog.atom'
    expect(response).to be_successful
  end

  describe 'entry' do
    let!(:media_object) { FactoryBot.create(:fully_searchable_media_object) }
    let(:updated_date) { media_object.modified_date.to_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ') }

    it 'returns information about a media object' do
      get '/catalog.atom'
      atom = Nokogiri::XML(response.body)
      atom.remove_namespaces!
      entry = atom.xpath('//entry[1]')
      expect(entry.at('id/text()').to_s).to eq media_object_url(media_object)
      expect(entry.at('updated/text()').to_s).to eq updated_date
      expect(entry.at("link[@type='application/json']/@href").to_s).to eq media_object_url(media_object, format: :json)
    end
  end
end
