# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

require 'rails_helper.rb'

describe 'CORS', type: :request do
  let(:media_object) { FactoryBot.create(:published_media_object) }
  let(:headers) { ['localhost', 'http://example.com', 'https://example.edu'] }

  it 'echoes the request origin in the CORS headers' do
    headers.each do |header|
      get "/media_objects/#{media_object.id}/manifest", headers: { 'HTTP_ORIGIN': header }
      expect(response.headers['Access-Control-Allow-Origin']).to eq(header)
    end
  end
end
