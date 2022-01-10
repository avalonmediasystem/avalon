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

RSpec.describe PlaylistItemsController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # PlaylistItem. As you add validations to PlaylistItem, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    { title: Faker::Lorem.word, start_time: "00:00:00", end_time: "00:01:37", master_file_id: master_file.id }
  end

  let(:invalid_attributes) do
    { title: "", start_time: 'not-a-time', end_time: 'not-a-time' }
  end

  let(:invalid_times) do
    { title: Faker::Lorem.word, start_time: 0.0, end_time: 'not-a-time', master_file_id: master_file.id }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PlaylistsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  let(:playlist_owner) { login_as :user }
  let(:playlist) { FactoryBot.create(:playlist, user: playlist_owner) }
  let(:playlist_item) { FactoryBot.create(:playlist_item, playlist: playlist, clip: clip) }
  let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }
  let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
  let(:clip) { AvalonClip.create(master_file: master_file) }

  describe 'security' do
    let(:playlist) { FactoryBot.create(:playlist) }

    context 'with unauthenticated user' do
      it "all return 401 unauthorized" do
        expect(post :create, params: { playlist_id: playlist.to_param, playlist_item: valid_attributes }).to have_http_status(:unauthorized)
        expect(put :update, params: { playlist_id: playlist.to_param, id: playlist_item.id }).to have_http_status(:unauthorized)
        expect(get :show, params: { playlist_id: playlist.to_param, id: playlist_item.id }, xhr: true).to have_http_status(:unauthorized)
        expect(get :source_details, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to have_http_status(:unauthorized)
        expect(get :markers, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to have_http_status(:unauthorized)
        expect(get :related_items, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to have_http_status(:unauthorized)
      end
      context 'with a public playlist' do
        let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

        it "returns the playlist item info snippets" do
          expect(get :show, params: { playlist_id: playlist.to_param, id: playlist_item.id }, xhr: true).to be_successful
          expect(get :source_details, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to be_successful
          expect(get :markers, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to be_successful
          expect(get :related_items, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to be_successful
        end
      end
      context 'with a private playlist and token' do
        let(:playlist) { FactoryBot.create(:playlist, :with_access_token) }

        it "returns the playlist item info page snippets" do
          expect(get :show, params: { playlist_id: playlist.to_param, id: playlist_item.id, token: playlist.access_token }, xhr: true).to be_successful
          expect(get :source_details, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id, token: playlist.access_token }).to be_successful
          expect(get :markers, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id, token: playlist.access_token }).to be_successful
          expect(get :related_items, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id, token: playlist.access_token }).to be_successful
        end
      end
    end
    context 'with end-user' do
      before do
        login_as :user
      end
      it "all return 401 unauthorized" do
        expect(post :create, params: { playlist_id: playlist.to_param, playlist_item: valid_attributes }).to have_http_status(:unauthorized)
        expect(put :update, params: { playlist_id: playlist.to_param, id: playlist_item.id }).to have_http_status(:unauthorized)
        expect(get :show, params: { playlist_id: playlist.to_param, id: playlist_item.id }, xhr: true).to have_http_status(:unauthorized)
        expect(get :source_details, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to have_http_status(:unauthorized)
        expect(get :markers, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to have_http_status(:unauthorized)
        expect(get :related_items, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to have_http_status(:unauthorized)
      end
      context 'with a public playlist' do
        let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

        it "returns the playlist item info snippets" do
          expect(get :show, params: { playlist_id: playlist.to_param, id: playlist_item.id }, xhr: true).to be_successful
          expect(get :source_details, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to be_successful
          expect(get :markers, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to be_successful
          expect(get :related_items, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }).to be_successful
        end
      end
      context 'with a private playlist and token' do
        let(:playlist) { FactoryBot.create(:playlist, :with_access_token) }

        it "returns the playlist item info page snippets" do
          expect(get :show, params: { playlist_id: playlist.to_param, id: playlist_item.id, token: playlist.access_token }, xhr: true).to be_successful
          expect(get :source_details, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id, token: playlist.access_token }).to be_successful
          expect(get :markers, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id, token: playlist.access_token }).to be_successful
          expect(get :related_items, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id, token: playlist.access_token }).to be_successful
        end
      end
    end
  end

  describe 'POST #create' do

    context 'with valid params' do
      it 'creates a new Playlist Item' do
        expect do
          post :create, params: { playlist_id: playlist.to_param, playlist_item: valid_attributes }, session: valid_session
        end.to change(PlaylistItem, :count).by(1)
      end

      it 'creates a new AvalonAnnotation' do
        expect do
          post :create, params: { playlist_id: playlist.to_param, playlist_item: valid_attributes }, session: valid_session
        end.to change(AvalonAnnotation, :count).by(1)
        expect(AvalonAnnotation.last.start_time).to eq (0.0)
        expect(AvalonAnnotation.last.end_time).to eq (97000.0)
      end

      it 'adds the Playlist Item to the playlist' do
        expect do
          post :create, params: { playlist_id: playlist.to_param, playlist_item: valid_attributes }, session: valid_session
        end.to change { playlist.reload.items.size }.by(1)
      end

      it 'responds with 201 CREATED status code' do
        post :create, params: { playlist_id: playlist.to_param, playlist_item: valid_attributes }, session: valid_session
        expect(response).to have_http_status(:created)
      end

      it 'responds with a flash message with link to playlist' do
        post :create, params: { playlist_id: playlist.to_param, playlist_item: valid_attributes }, session: valid_session
        expect(JSON.parse(response.body)['message']).to include('Add to playlist was successful.')
        expect(JSON.parse(response.body)['message']).to include(playlist_url(playlist))
      end
    end

    context 'with invalid params' do
      it 'invalid times respond with a 400 BAD REQUEST' do
        post :create, params: { playlist_id: playlist.to_param, playlist_item: invalid_times }, session: valid_session
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
  describe 'PATCH #update' do
    let!(:video_master_file) { FactoryBot.create(:master_file, duration: "200000") }
    let!(:clip) { AvalonClip.create(master_file: video_master_file, title: Faker::Lorem.word, comment: Faker::Lorem.sentence, start_time: 1000, end_time: 2000) }
    let!(:playlist_item) { PlaylistItem.create!(playlist: playlist, clip: clip) }

    context 'with valid params' do
      it 'updates Playlist Item' do
        expect do
          patch :update, params: { playlist_id: playlist.id, id: playlist_item.id, playlist_item: { title: Faker::Lorem.word, start_time:'00:20', end_time:'1:20' } }, session: valid_session
        end.to change{ playlist_item.reload.title }
      end
    end
    context 'with invalid params' do
      it 'fails to update Playlist Item' do
        expect do
          patch :update, params: { playlist_id: playlist.id, id: playlist_item.id, playlist_item: { title: Faker::Lorem.word, start_time:'00:20', end_time:'not-a-time' } }, session: valid_session
        end.not_to change{ playlist_item.reload.title }
      end
    end
  end

  describe 'GET #source_details' do
    it 'returns HTML' do
      get :source_details, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:_current_item)
    end
  end

  describe 'GET #markers' do
    it 'returns HTML' do
      get :markers, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:_markers)
    end
  end

  describe 'GET #related_items' do
    it 'returns HTML' do
      allow_any_instance_of(Playlist).to receive(:related_clips).and_return([clip]);
      get :related_items, params: { playlist_id: playlist.to_param, playlist_item_id: playlist_item.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:_related_items)
    end
  end
end
