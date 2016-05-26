require 'spec_helper'

RSpec.describe PlaylistItemsController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # PlaylistItem. As you add validations to PlaylistItem, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    { title: Faker::Lorem.word, start_time: "00:00:00", end_time: "00:01:37", master_file_id: master_file.pid }
  end

  let(:invalid_attributes) do
    { title: "", start_time: 'not-a-time', end_time: 'not-a-time' }
  end

  let(:invalid_times) do
    { title: Faker::Lorem.word, start_time: 0.0, end_time: 'not-a-time', master_file_id: master_file.pid }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PlaylistsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  let(:user) { login_as :user }
  let(:playlist) { FactoryGirl.create(:playlist, user: user) }
  let(:master_file) { FactoryGirl.create(:master_file, duration: "100000") }

  describe 'security' do
    let(:playlist) { FactoryGirl.create(:playlist) }
    let(:playlist_item) { FactoryGirl.create(:playlist_item, playlist: playlist) }
    context 'with unauthenticated user' do
      it "all routes should redirect to sign in" do
        expect(post :create, playlist_id: playlist.to_param, playlist_item: valid_attributes).to redirect_to(new_user_session_path)
        expect(put :update, playlist_id: playlist.to_param, id: playlist_item.id).to redirect_to(new_user_session_path)
      end
    end
    context 'with end-user' do
      before do
        login_as :user
      end
     it "all routes should redirect to /" do
        expect(post :create, playlist_id: playlist.to_param, playlist_item: valid_attributes).to have_http_status(:unauthorized)
        expect(put :update, playlist_id: playlist.to_param, id: playlist_item.id).to have_http_status(:unauthorized)
      end
    end
  end


  describe 'POST #create' do

    context 'with valid params' do
      it 'creates a new Playlist Item' do
        expect do
          post :create, { playlist_id: playlist.to_param, playlist_item: valid_attributes }, valid_session
        end.to change(PlaylistItem, :count).by(1)
      end

      it 'creates a new AvalonAnnotation' do
        expect do
          post :create, { playlist_id: playlist.to_param, playlist_item: valid_attributes }, valid_session
        end.to change(AvalonAnnotation, :count).by(1)
        expect(AvalonAnnotation.last.start_time).to eq (0.0)
        expect(AvalonAnnotation.last.end_time).to eq (97000.0)
      end

      it 'adds the Playlist Item to the playlist' do
        expect do
          post :create, { playlist_id: playlist.to_param, playlist_item: valid_attributes }, valid_session
        end.to change { playlist.reload.items.size }.by(1)
      end

      it 'responds with 201 CREATED status code' do
        post :create, { playlist_id: playlist.to_param, playlist_item: valid_attributes }, valid_session
        expect(response).to have_http_status(:created)
      end

      it 'responds with a flash message with link to playlist' do
        post :create, { playlist_id: playlist.to_param, playlist_item: valid_attributes }, valid_session
        expect(JSON.parse(response.body)['message']).to include('Add to playlist was successful.')
        expect(JSON.parse(response.body)['message']).to include(playlist_url(playlist))
      end
    end

    context 'with invalid params' do
      it 'invalid times respond with a 400 BAD REQUEST' do
        post :create, { playlist_id: playlist.to_param, playlist_item: invalid_times }, valid_session
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
  describe 'PATCH #update' do
    let!(:video_master_file) { FactoryGirl.create(:master_file, duration: "200000") }
    let!(:annotation) { AvalonAnnotation.create(master_file: video_master_file, title: Faker::Lorem.word, comment: Faker::Lorem.sentence, start_time: 1000, end_time: 2000) }
    let!(:playlist_item) { PlaylistItem.create!(playlist_id: playlist.id, annotation_id: annotation.id) }

    context 'with valid params' do
      it 'updates Playlist Item' do
        expect do
          patch :update, { playlist_id: playlist.id, id: playlist_item.id, playlist_item: { title: Faker::Lorem.word, start_time:'00:20', end_time:'1:20' }}, valid_session
        end.to change{ playlist_item.reload.title }
      end
    end
    context 'with invalid params' do
      it 'fails to update Playlist Item' do
        expect do
          patch :update, { playlist_id: playlist.id, id: playlist_item.id, playlist_item: { title: Faker::Lorem.word, start_time:'00:20', end_time:'not-a-time' }}, valid_session
        end.not_to change{ playlist_item.reload.title }
      end
    end
  end
end
