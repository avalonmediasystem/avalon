# Copyright 2011-2026, The Trustees of Indiana University and Northwestern
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

describe 'Routing Error Handling', type: :request do
  it 'responds with 404 page for html request' do
    get '/fake/route', params: { format: :html }
    expect(response.status).to eq(404)
    expect(response.body).to include('The page you were looking for doesn’t exist (404 Not found)')
  end

  it 'responds with json error for json request' do
    get '/fake/route', params: { format: :json }
    expect(response.status).to eq(404)
    expect(JSON.parse(response.body)).to eq("errors" => ["API action does not exist. Check that your URL and HTTP request method are correct."])
  end

  it 'responds with 404 status for other request' do
    get '/fake/route', params: { format: :atom }
    expect(response.status).to eq(404)
    expect(response.body).to be_empty
  end
end
