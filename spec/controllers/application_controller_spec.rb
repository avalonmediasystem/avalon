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

describe ApplicationController do
  controller do
    def index

    end

    def create
      head :ok
    end

    def show
      raise Ldp::Gone
    end
  end

  context "normal auth" do
    it "should check for authenticity token" do
      expect(controller).to receive(:verify_authenticity_token)
      post :create
    end
  end
  context "ingest API" do
    before do
      ApiToken.create token: 'secret_token', username: 'archivist1@example.com', email: 'archivist1@example.com'
    end
    it "should not check for authenticity token for API requests" do
      request.headers['Avalon-Api-Key'] = 'secret_token'
      expect(controller).not_to receive(:verify_authenticity_token)
      post :create
    end
  end

  describe '#get_user_collections' do
    let!(:collection1) { FactoryBot.create(:collection) }
    let!(:collection2) { FactoryBot.create(:collection) }

    it 'returns all collections for an administrator' do
      login_as :administrator
      expect(controller.get_user_collections).to include(have_attributes(id: collection1.id))
      expect(controller.get_user_collections).to include(have_attributes(id: collection2.id))
    end
    it 'returns only relevant collections for a manager' do
      login_user collection1.managers.first
      expect(controller.get_user_collections).to include(have_attributes(id: collection1.id))
      expect(controller.get_user_collections).not_to include(have_attributes(id: collection2.id))
    end
    it 'returns no collections for an end-user' do
      login_as :user
      expect(controller.get_user_collections).to be_empty
    end
    it 'returns no collections to end-user, even when passing user param' do
      login_as :user
      expect(controller.get_user_collections collection1.managers.first).to be_empty
    end
    it 'returns requested user\'s collections for an administrator' do
      login_as :administrator
      expect(controller.get_user_collections collection1.managers.first).to include(have_attributes(id: collection1.id))
      expect(controller.get_user_collections collection1.managers.first).not_to include(have_attributes(id: collection2.id))
    end
  end

  describe "exceptions handling" do
    it "renders deleted_pid template" do
      get :show, params: { id: 'deleted-id' }
      expect(response).to render_template("errors/deleted_pid")
    end

    context 'raise_on_connection_error disabled' do
      let(:request_context) { { uri: Addressable::URI.parse("http://example.com"), body: "request_context" } }
      let(:e) { { body: "error_response" } }

      before :each do
        allow(Settings.app_controller.solr_and_fedora).to receive(:raise_on_connection_error).and_return(false)
      end

      [RSolr::Error::ConnectionRefused, RSolr::Error::Timeout, Blacklight::Exceptions::ECONNREFUSED, Faraday::ConnectionFailed].each do |error_code|
        it "rescues #{error_code} errors" do
          raised_error = if error_code == RSolr::Error::ConnectionRefused
                           error_code.new(request_context)
                         elsif error_code == RSolr::Error::Timeout
                           error_code.new(request_context, e)
                         else
                           error_code
                         end
          allow(controller).to receive(:show).and_raise(raised_error)
          allow_any_instance_of(Exception).to receive(:backtrace).and_return(["Test trace"])
          allow_any_instance_of(Exception).to receive(:message).and_return('Connection reset by peer')
          expect(Rails.logger).to receive(:error).with(error_code.to_s + ': Connection reset by peer\nTest trace')
          expect { get :show, params: { id: 'abc1234' } }.to_not raise_error
        end

        it "html request renders error template for #{error_code} errors" do
          raised_error = if error_code == RSolr::Error::ConnectionRefused
                           error_code.new(request_context)
                         elsif error_code == RSolr::Error::Timeout
                           error_code.new(request_context, e)
                         else
                           error_code
                         end
          error_template = error_code == Faraday::ConnectionFailed ? 'errors/fedora_connection' : 'errors/solr_connection'
          allow(controller).to receive(:show).and_raise(raised_error)
          get :show, params: { id: 'abc1234' }
          expect(response).to render_template(error_template)
        end

        it 'non-html request provides JSON response' do
          [:json, :text, :m3u8].each do |type|
            raised_error = if error_code == RSolr::Error::ConnectionRefused
                             error_code.new(request_context)
                           elsif error_code == RSolr::Error::Timeout
                             error_code.new(request_context, e)
                           else
                             error_code
                           end
            allow_any_instance_of(Exception).to receive(:backtrace).and_return(["Test trace"])
            allow_any_instance_of(Exception).to receive(:message).and_return('Connection reset by peer')
            allow(controller).to receive(:show).and_raise(raised_error)
            get :show, params: { id: 'abc1234' }, format: type
            expect(response.status).to eq 503
            expect(response.content_type).to eq("application/json; charset=utf-8")
            parsed_body = JSON.parse(response.body)
            expect(parsed_body).to eq({ "errors" => ["Connection reset by peer"] })
          end
        end
      end
    end

    context 'raise_on_connection_error enabled' do
      let(:request_context) { { uri: Addressable::URI.parse("http://example.com"), body: "request_context" } }
      let(:e) { { body: "error_response" } }

      [RSolr::Error::ConnectionRefused, RSolr::Error::Timeout, Blacklight::Exceptions::ECONNREFUSED, Faraday::ConnectionFailed].each do |error_code|
        it "raises #{error_code} errors" do
          raised_error = if error_code == RSolr::Error::ConnectionRefused
                           error_code.new(request_context)
                         elsif error_code == RSolr::Error::Timeout
                           error_code.new(request_context, e)
                         else
                           error_code
                         end
          allow(Settings.app_controller.solr_and_fedora).to receive(:raise_on_connection_error).and_return(true)
          allow(controller).to receive(:show).and_raise(raised_error)
          allow_any_instance_of(Exception).to receive(:backtrace).and_return(["Test trace"])
          allow_any_instance_of(Exception).to receive(:message).and_return('Connection reset by peer')
          expect { get :show, params: { id: 'abc1234' } }.to raise_error(error_code, 'Connection reset by peer')
        end
      end
    end
  end

  describe "rewrite_v4_ids" do
    it 'skips when id is not a Fedora 3 pid' do
      get :show, params: { id: 'abc1234' }
      expect(response).not_to have_http_status(304)
    end

    it 'skips post requests' do
      post :create, params: { id: 'avalon:1234' }
      expect(response).not_to have_http_status(304)
    end
  end

  describe "layout" do
    render_views

    it 'renders avalon layout' do
      get :show, params: { id: 'abc1234' }
      expect(response).to render_template("layouts/avalon")
    end

    it 'renders google analytics partial' do
      get :show, params: { id: 'abc1234' }
      expect(response).to render_template("modules/_google_analytics")
    end

    it 'defines an after invite hook' do
      expect(controller.after_invite_path_for(nil)).to eq('/persona/users')
    end
  end

  describe 'remove_zero_width_chars' do
    it 'removes zero-width chars from string params' do
      post :create, params: { id: 'abc1234', key: "\u200Bvalue\u2060" }
      expect(controller.params[:key]).to eq "value"
    end

    it 'removes zero-width chars from array params' do
      post :create, params: { id: 'abc1234', key: ["\u200Bvalue\u2060"] }
      expect(controller.params[:key]).to eq ["value"]
    end

    it 'removes zero-width chars from hash params' do
      post :create, params: { id: 'abc1234', key: { subkey: "\u200Bvalue\u2060" } }
      expect(controller.params[:key][:subkey]).to eq "value"
    end
  end
end
