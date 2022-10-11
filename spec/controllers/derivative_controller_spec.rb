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

require 'rails_helper'

describe DerivativesController, type: :controller do
  describe 'authorize' do
    let(:derivative) { FactoryBot.create(:derivative, :with_master_file) }
    let(:auth_path) { derivative.location_url.split(/:/).last }
    let(:target) { derivative.master_file.id }
    let(:session) { { } }
    let(:token) { StreamToken.find_or_create_session_token(session, target) }

    it "no token" do
      get :authorize, format: :text
      expect(response).to be_forbidden
    end

    it "valid token, no path" do
      get :authorize, params: { token: token, format: :text }
      expect(response).to be_accepted
      expect(response.body).to eq(auth_path)
    end

    it "invalid token, no path" do
      get :authorize, params: { token: "X#{token}X", format: :text }
      expect(response).to be_forbidden
    end

    it "valid token, valid path" do
      post :authorize, params: { token: token, name: auth_path, format: :text }
      expect(response).to be_accepted
      expect(response.body).to eq(auth_path)
    end

    it "valid token, invalid path" do
      post :authorize, params: { token: token, name: "WRONG_PATH", format: :text }
      expect(response).to be_forbidden
    end

    it "bad token" do
      allow(StreamToken).to receive(:find_or_create_session_token).and_return(NoMethodError)
      get :authorize, params: { token: token, format: :text }
      expect(response).to be_forbidden
    end
  end
end
