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
require 'fileutils'

describe VocabularyController, type: :controller do
  render_views

  before(:all) {
    FileUtils.cp_r Settings.controlled_vocabulary.path, 'spec/fixtures/controlled_vocabulary.yml.tmp'
    Avalon::ControlledVocabulary.class_variable_set :@@path, Rails.root.join('spec/fixtures/controlled_vocabulary.yml.tmp')
  }
  after(:all) {
    File.delete('spec/fixtures/controlled_vocabulary.yml.tmp')
    Avalon::ControlledVocabulary.class_variable_set :@@path, Rails.root.join(Settings.controlled_vocabulary.path)
  }

  let(:administrator) { FactoryBot.create(:administrator) }

  before(:each) do
    ApiToken.create token: 'secret_token', username: administrator.username, email: administrator.email
    request.headers['Avalon-Api-Key'] = 'secret_token'
  end

  describe 'security' do
    let(:vocab) { :units }
    describe 'ingest api' do
      it "all routes should return 401 when no token is present" do
        request.headers['Avalon-Api-Key'] = nil
        expect(get :index, format: 'json').to have_http_status(401)
        expect(get :show, params: { id: vocab, format: 'json' }).to have_http_status(401)
        expect(put :update, params: { id: vocab, format: 'json' }).to have_http_status(401)
        expect(patch :update, params: { id: vocab, format: 'json' }).to have_http_status(401)
      end
      it "all routes should return 403 when a bad token in present" do
        request.headers['Avalon-Api-Key'] = 'badtoken'
        expect(get :index, format: 'json').to have_http_status(403)
        expect(get :show, params: { id: vocab, format: 'json' }).to have_http_status(403)
        expect(put :update, params: { id: vocab, format: 'json' }).to have_http_status(403)
        expect(patch :update, params: { id: vocab, format: 'json' }).to have_http_status(403)
      end
    end
    describe 'normal auth' do
      context 'with end-user' do
        before do
          request.headers['Avalon-Api-Key'] = nil
          login_as :user
        end
        it "all routes should redirect to /" do
          expect(get :index, format: 'json').to have_http_status(401)
          expect(get :show, params: { id: vocab, format: 'json' }).to have_http_status(401)
          expect(put :update, params: { id: vocab, format: 'json' }).to have_http_status(401)
          expect(patch :update, params: { id: vocab, format: 'json' }).to have_http_status(401)
        end
      end
    end
  end

  describe "#index" do
    it "should return vocabulary for entire app" do
      get 'index', format:'json'
      expect(JSON.parse(response.body)).to include('units','note_types','identifier_types')
    end
  end
  describe "#show" do
    it "should return a particular vocabulary" do
      get 'show', params: { format:'json', id: :units }
      expect(JSON.parse(response.body)).to include('Default Unit')
    end
    it "should return 404 if requested vocabulary not present" do
      get 'show', params: { format:'json', id: :doesnt_exist }
      expect(response.status).to eq(404)
      expect(JSON.parse(response.body)["errors"].class).to eq Array
      expect(JSON.parse(response.body)["errors"].first.class).to eq String
    end
  end
  describe "#update" do
    it "should add unit to controlled vocabulary" do
      put 'update', params: { format:'json', id: :units, entry: 'New Unit' }
      expect(Avalon::ControlledVocabulary.vocabulary[:units]).to include("New Unit")
    end
    it "should return 404 if requested vocabulary not present" do
      put 'update', params: { format:'json', id: :doesnt_exist, entry: 'test' }
      expect(response.status).to eq(404)
      expect(JSON.parse(response.body)["errors"].class).to eq Array
      expect(JSON.parse(response.body)["errors"].first.class).to eq String
    end
    it "should return 422 if no new value sent" do
      put 'update', params: { format:'json', id: :units }
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["errors"].class).to eq Array
      expect(JSON.parse(response.body)["errors"].first.class).to eq String
    end
    it "should return 422 if update fails" do
      allow(Avalon::ControlledVocabulary).to receive(:vocabulary=).and_return(false)
      put 'update', params: { format:'json', id: :units }
      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["errors"].class).to eq Array
      expect(JSON.parse(response.body)["errors"].first.class).to eq String
    end
  end

end
