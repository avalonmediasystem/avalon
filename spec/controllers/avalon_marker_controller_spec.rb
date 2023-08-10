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

require 'rails_helper'

describe AvalonMarkerController, type: :controller do

  let(:valid_session) { {} }
  let(:master_file) { FactoryBot.create(:master_file, :with_derivative, media_object: media_object, duration: "200000") }
  let(:media_object) { FactoryBot.create(:published_media_object, read_users: [user]) }
  let(:avalon_clip) { FactoryBot.create(:avalon_clip, master_file: master_file) }
  let(:user) { login_as :user }
  let(:playlist) { FactoryBot.create(:playlist, user: user) }
  let(:playlist_item) { FactoryBot.create(:playlist_item, playlist: playlist, clip: avalon_clip) }
  let(:avalon_marker) { FactoryBot.create(:avalon_marker, playlist_item: playlist_item, master_file: master_file) }
  let(:create_annotation_json) do
    {
      "@context" => "http://www.w3.org/ns/anno.jsonld",
      type: "Annotation",
      body: {
        type: "TextualBody",
        value: "A playlist marker title"
      },
      target: "#{Rails.application.routes.url_helpers.manifest_playlist_url(playlist.id)}/canvas/#{playlist_item.id}#t=2.234"
    }
  end
  let(:update_annotation_json) do
    {
      "@context" => "http://www.w3.org/ns/anno.jsonld",
      id: Rails.application.routes.url_helpers.avalon_marker_url(avalon_marker.id),
      type: "Annotation",
      body: {
        type: "TextualBody",
        value: Faker::Lorem.word
      },
      target: "#{Rails.application.routes.url_helpers.manifest_playlist_url(playlist.id)}/canvas/#{playlist_item.id}#t=#{avalon_marker.start_time / 1000}"
    }
  end


  describe 'security' do
    let(:playlist) { FactoryBot.create(:playlist) }
    let(:playlist_item) { FactoryBot.create(:playlist_item, playlist: playlist) }
    let(:media_object) { FactoryBot.create(:published_media_object) }
    context 'with unauthenticated user' do
      it "all routes should redirect to sign in" do
        expect(get :show, params: { id: avalon_marker.id }).to render_template('errors/restricted_pid')
        expect(post :create, body: create_annotation_json.to_json).to render_template('errors/restricted_pid')
        expect(put :update, params: { id: avalon_marker.id }, body: update_annotation_json.to_json).to render_template('errors/restricted_pid')
        expect(delete :destroy, params: { id: avalon_marker.id }).to render_template('errors/restricted_pid')
      end
    end
    context 'with end-user' do
      before do
        login_as :user
      end
      it "all routes should redirect to /" do
        expect(get :show, params: { id: avalon_marker.id }).to have_http_status(:unauthorized)
        expect(post :create, body: create_annotation_json.to_json).to have_http_status(:unauthorized)
        expect(put :update, params: { id: avalon_marker.id }, body: update_annotation_json.to_json).to have_http_status(:unauthorized)
        expect(delete :destroy, params: { id: avalon_marker.id }).to have_http_status(:unauthorized)
      end
    end
  end

  describe '#show' do
    it 'returns a web annotation json object' do
      get :show, params: { id: avalon_marker.id }
      expect { JSON.parse(response.body) }.not_to raise_error
      response_json = JSON.parse(response.body)
      expect(response_json["id"]).to include avalon_marker.id.to_s
      expect(response_json["motivation"]).to eq "highlighting"
      expect(response_json["body"]["value"]).to eq avalon_marker.title
      expect(response_json["target"]).to eq "#{Rails.application.routes.url_helpers.manifest_playlist_url(playlist.id)}/canvas/#{playlist_item.id}#t=#{avalon_marker.start_time / 1000}"
    end
  end

  describe '#create' do
    it 'can create a marker and display it as JSON' do
      post 'create', body: create_annotation_json.to_json, format: :json
      expect { JSON.parse(response.body) }.not_to raise_error
      response_json = JSON.parse(response.body)
      expect(response_json["id"]).to be_present
    end
    xit 'returns an error when the master file is not supplied' do
      expect(post 'create', params: { marker:{ playlist_item_id: playlist_item.id } }).to have_http_status(400)
    end
    xit 'returns an error when the master file cannot be found' do
      expect(post 'create', params: { marker:{ master_file_id: 'OC', playlist_item_id: playlist_item.id } }).to have_http_status(500)
    end
    xit 'returns an error when the playlist item is not supplied' do
      expect(post 'create', params: { marker:{ master_file_id: master_file.id } }).to have_http_status(401)
    end
    xit 'returns an error when the playlist item cannot be found' do
      expect(post 'create', params: { marker:{ master_file_id: master_file.id, playlist_item_id: 'OC' } }).to have_http_status(500)
    end
  end

  describe 'updating a marker' do
    let(:annotation_json) do
      {
        "@context" => "http://www.w3.org/ns/anno.jsonld",
        id: Rails.application.routes.url_helpers.avalon_marker_url(avalon_marker.id),
        type: "Annotation",
        body: {
          type: "TextualBody",
          value: "30 Seconds of Fun"
        },
        target: "#{Rails.application.routes.url_helpers.manifest_playlist_url(playlist.id)}/canvas/#{playlist_item.id}#t=60.000"
      }
    end

    it 'can update a marker and display it as JSON' do
      avalon_marker.save!
      put 'update', params: { id: avalon_marker.id }, body: annotation_json.to_json
      expect { JSON.parse(response.body) }.not_to raise_error
      marker = AvalonMarker.find(avalon_marker.id)
      expect(marker.start_time).to eq(60000.0)
      expect(marker.title).to eq('30 Seconds of Fun')
    end
    it 'raises an error when the marker cannot be found' do
      expect(put 'update', params: { id: 'OC' }).to have_http_status(500)
    end
  end

  describe 'destroying a marker' do
    it 'can destroy a marker and returns the result as JSON' do
      avalon_marker.save!
      delete 'destroy', params: { id: avalon_marker.id }
      resp = JSON.parse(response.body)
      expect(resp['action']).to match('destroy')
      expect(resp['id']).to match(avalon_marker.id)
      expect(resp['success']).to be_truthy
    end
    it 'raises an error when the marker is not found to destroy' do
      expect(delete 'destroy', params: { id: 'OC' }).to have_http_status(500)
    end
  end
end
