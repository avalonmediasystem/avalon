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

require 'rails_helper'

describe 'oembed', type: :request do
  let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
  let(:master_file) { FactoryBot.create(:master_file, media_object: media_object, title: 'Test Video') }

  before do
    allow(Settings).to receive(:name).and_return('Test')

    @hash = {
      "version" => "1.0",
      "type" => "video",
      "provider_name" => 'Test',
      "provider_url" => "http://test.host",
      "width" => 600,
      "height" => 337,
      "title" => master_file.display_title,
      "html" => master_file.embed_code(600, { urlappend: '/embed' })
    }

    media_object.sections = [master_file]
    media_object.save
  end

  context 'invalid requests' do
    it 'missing url param returns a 400' do
      get '/oembed.json'
      expect(response).to_not be_successful
      expect(response.status).to eq(400)
      result = JSON.parse(response.body)
      expect(result).to eq({ 'errors' => ['Invalid request. Missing "url" parameter.'] })
    end

    it 'missing item returns a 404' do
      get '/oembed.xml', params: { url: 'http://example.com/1234' }
      expect(response).to_not be_successful
      expect(response.status).to eq(404)
      result = JSON.parse(response.body)
      expect(result).to eq({ 'errors' => ['1234 not found'] })
    end

    context 'restricted item' do
      let(:master_file) { FactoryBot.create(:master_file, :with_media_object) }

      it 'returns a 401' do
        get '/oembed.xml', params: { url: id_section_media_object_url(master_file.media_object_id, master_file.id) }
        expect(response).to_not be_successful
        expect(response.status).to eq(401)
        result = JSON.parse(response.body)
        expect(result).to eq({ 'errors' => ['You do not have sufficient privileges'] })
      end
    end
  end

  context 'html request' do
    it 'returns a json hash' do
      get '/oembed', params: { url: id_section_media_object_url(master_file.media_object_id, master_file.id) }
      expect(response.content_type).to eq("text/html; charset=utf-8")
      result = JSON.parse(response.body)
      expect(result).to eq(@hash)
    end
  end

  context 'json request' do
    it 'returns a json hash' do
      get '/oembed.json', params: { url: id_section_media_object_url(master_file.media_object_id, master_file.id) }
      expect(response.content_type).to eq("application/json; charset=utf-8")
      result = JSON.parse(response.body)
      expect(result).to eq(@hash)
    end
  end

  context 'xml request' do
    it 'returns an xml document' do
      get '/oembed.xml', params: { url: id_section_media_object_url(master_file.media_object_id, master_file.id) }
      expect(response.content_type).to eq("application/xml; charset=utf-8")
      expect(response.body).to eq(@hash.to_xml({ root: 'oembed' }))
    end
  end
end
