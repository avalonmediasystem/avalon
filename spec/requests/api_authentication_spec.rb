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

require 'rails_helper.rb'

# These tests are for the #handle_api_request method in the ApplicationController
describe "API authentication", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let!(:media_object) { FactoryBot.create(:published_media_object, visibility: 'private', read_groups: ['ldap_group_2']) }
  let!(:unauthorized_media_object) { FactoryBot.create(:published_media_object, visibility: 'private') }
  let(:ldap_groups) { ['ldap_group_1'] }
  before do
    ApiToken.create token: 'secret_token', username: user.username, email: user.email
    allow_any_instance_of(User).to receive(:ldap_groups).and_return(ldap_groups)
  end
  it "sets the session information properly" do
    get "/media_objects/#{media_object.id}.json", headers: { 'Avalon-Api-Key': 'secret_token' }
    expect(@controller.user_session[:json_api_login]).to eq true
    expect(@controller.user_session[:full_login]).to be false
    expect(@controller.user_session[:virtual_groups]).to eq(['ldap_group_1'])
  end
  context 'without external groups' do
    let(:ldap_groups) { [] }
    it "does not allow user to access unauthorized media object" do
      get "/media_objects/#{media_object.id}.json", headers: { 'Avalon-Api-Key': 'secret_token' }
      expect(response.status).to be 401
    end
  end
  context 'with external groups' do
    let(:ldap_groups) { ['ldap_group_2'] }
    context '/media_objects/:id.json endpoint' do
      it 'allows the user to access authorized media objects' do
        get "/media_objects/#{media_object.id}.json", headers: { 'Avalon-Api-Key': 'secret_token' }
        expect(response.status).to be 200
        expect(response.body).to include(media_object.id)
      end
      it 'does not allow user to access unauthorized media objects' do
        get "/media_objects/#{unauthorized_media_object.id}.json", headers: { 'Avalon-Api-Key': 'secret_token' }
        expect(response.status).to be 401
      end
    end
  end
end
