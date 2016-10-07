require 'rails_helper'

describe DerivativesController, type: :controller do
  describe 'authorize' do
    let(:derivative) { FactoryGirl.create(:derivative, :with_master_file) }
    let(:auth_path) { derivative.location_url.split(/:/).last }
    let(:target) { derivative.master_file.id }
    let(:session) { { } }
    let(:token) { StreamToken.find_or_create_session_token(session, target) }
    
    it "no token" do
      get :authorize, format: :text
      expect(response).to be_forbidden
    end
    
    it "valid token, no path" do
      get :authorize, token: token, format: :text
      expect(response).to be_accepted
      expect(response.body).to eq(auth_path)
    end

    it "invalid token, no path" do
      get :authorize, token: "X#{token}X", format: :text
      expect(response).to be_forbidden
    end
    
    it "valid token, valid path" do
      post :authorize, token: token, name: auth_path, format: :text
      expect(response).to be_accepted
      expect(response.body).to eq(auth_path)
    end

    it "valid token, invalid path" do
      post :authorize, token: token, name: "WRONG_PATH", format: :text
      expect(response).to be_forbidden
    end
  end
end
