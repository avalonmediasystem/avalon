require 'spec_helper'

RSpec.describe PlaylistItemsController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # PlaylistItem. As you add validations to PlaylistItem, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    { title: Faker::Lorem.word, start_time: 0.0, end_time: 100.0, master_file_id: master_file.pid }
  end

  let(:invalid_attributes) do
    { playlist_id: 'not-a-playlist-id', master_file_id: 'avalon:bad-pid', start_time: 'not-a-time', end_time: 'not-a-time' }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PlaylistsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  let(:user) { login_as :user }
  let(:playlist) { Playlist.create!({ title: Faker::Lorem.word, visibility: Playlist::PUBLIC, user: user }) }
  let(:master_file) { FactoryGirl.create(:master_file) }


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
        expect(flash[:success]).to be_present
        expect(flash[:success]).to include("success")
        expect(flash[:success]).to include(playlist_url(playlist))
      end
    end

    context 'with invalid params' do
      xit 'responds with a 400 BAD REQUEST' do
        post :create, { playlist_id: playlist.to_param, playlist_item: invalid_attributes }, valid_session
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

end
