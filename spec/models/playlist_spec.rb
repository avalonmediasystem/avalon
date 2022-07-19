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
require 'cancan/matchers'

RSpec.describe Playlist, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:visibility) }
    it { is_expected.to validate_inclusion_of(:visibility).in_array([Playlist::PUBLIC, Playlist::PRIVATE, Playlist::PRIVATE_WITH_TOKEN]) }
  end

  describe 'abilities' do
    subject{ ability }
    let(:ability){ Ability.new(user) }
    let(:user){ FactoryBot.create(:user) }

    context 'when administrator' do
      let(:playlist) { FactoryBot.create(:playlist) }
      let(:user) { FactoryBot.create(:administrator) }

      it{ is_expected.to be_able_to(:manage, playlist) }
      it{ is_expected.to be_able_to(:create, playlist) }
      it{ is_expected.to be_able_to(:read, playlist) }
      it{ is_expected.to be_able_to(:update, playlist) }
      it{ is_expected.to be_able_to(:delete, playlist) }
    end

    context 'when owner' do
      let(:playlist) { FactoryBot.create(:playlist, user: user) }

      it{ is_expected.to be_able_to(:manage, playlist) }
      it{ is_expected.to be_able_to(:duplicate, playlist)}
      it{ is_expected.to be_able_to(:create, playlist) }
      it{ is_expected.to be_able_to(:read, playlist) }
      it{ is_expected.to be_able_to(:update, playlist) }
      it{ is_expected.to be_able_to(:delete, playlist) }
    end

    context 'when other user' do
      context('playlist public') do
        let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

        it{ is_expected.not_to be_able_to(:manage, playlist) }
        it{ is_expected.to be_able_to(:duplicate, playlist) }
        it{ is_expected.not_to be_able_to(:create, playlist) }
        it{ is_expected.to be_able_to(:read, playlist) }
        it{ is_expected.not_to be_able_to(:update, playlist) }
        it{ is_expected.not_to be_able_to(:delete, playlist) }
      end
      context('playlist private') do
        let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PRIVATE) }

        it{ is_expected.not_to be_able_to(:manage, playlist) }
        it{ is_expected.not_to be_able_to(:duplicate, playlist) }
        it{ is_expected.not_to be_able_to(:create, playlist) }
        it{ is_expected.not_to be_able_to(:read, playlist) }
        it{ is_expected.not_to be_able_to(:update, playlist) }
        it{ is_expected.not_to be_able_to(:delete, playlist) }
      end
      context('playlist private with token') do
        let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PRIVATE_WITH_TOKEN) }
        context('when no token given') do
          it{ is_expected.not_to be_able_to(:manage, playlist) }
          it{ is_expected.not_to be_able_to(:duplicate, playlist) }
          it{ is_expected.not_to be_able_to(:create, playlist) }
          # One is still not allowed to read the playlist, but the controller bypasses this when the token is passed as a query param
          it{ is_expected.not_to be_able_to(:read, playlist) }
          it{ is_expected.not_to be_able_to(:update, playlist) }
          it{ is_expected.not_to be_able_to(:delete, playlist) }
        end
        context('when token given') do
          let(:ability) { Ability.new(user, {playlist_token: playlist.access_token}) }
          it{ is_expected.not_to be_able_to(:manage, playlist) }
          it{ is_expected.to be_able_to(:duplicate, playlist) }
          it{ is_expected.not_to be_able_to(:create, playlist) }
          it{ is_expected.to be_able_to(:read, playlist) }
          it{ is_expected.not_to be_able_to(:update, playlist) }
          it{ is_expected.not_to be_able_to(:delete, playlist) }
        end
      end
    end
    context 'when not logged in' do
      let(:ability) { Ability.new(nil) }
      context('playlist public') do
        let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

        it{ is_expected.not_to be_able_to(:manage, playlist) }
        it{ is_expected.not_to be_able_to(:duplicate, playlist) }
        it{ is_expected.not_to be_able_to(:create, playlist) }
        it{ is_expected.to be_able_to(:read, playlist) }
        it{ is_expected.not_to be_able_to(:update, playlist) }
        it{ is_expected.not_to be_able_to(:delete, playlist) }
      end
      context('playlist private') do
        let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PRIVATE) }

        it{ is_expected.not_to be_able_to(:manage, playlist) }
        it{ is_expected.not_to be_able_to(:duplicate, playlist) }
        it{ is_expected.not_to be_able_to(:create, playlist) }
        it{ is_expected.not_to be_able_to(:read, playlist) }
        it{ is_expected.not_to be_able_to(:update, playlist) }
        it{ is_expected.not_to be_able_to(:delete, playlist) }
      end
      context('playlist private with token') do
        let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PRIVATE_WITH_TOKEN) }
        context('when no token given') do
          it{ is_expected.not_to be_able_to(:manage, playlist) }
          it{ is_expected.not_to be_able_to(:duplicate, playlist) }
          it{ is_expected.not_to be_able_to(:create, playlist) }
          # One is still not allowed to read the playlist, but the controller bypasses this when the token is passed as a query param
          it{ is_expected.not_to be_able_to(:read, playlist) }
          it{ is_expected.not_to be_able_to(:update, playlist) }
          it{ is_expected.not_to be_able_to(:delete, playlist) }
        end
        context('when token given') do
          let(:ability) { Ability.new(nil, {playlist_token: playlist.access_token}) }
          it{ is_expected.not_to be_able_to(:manage, playlist) }
          it{ is_expected.not_to be_able_to(:duplicate, playlist) }
          it{ is_expected.not_to be_able_to(:create, playlist) }
          it{ is_expected.to be_able_to(:read, playlist) }
          it{ is_expected.not_to be_able_to(:update, playlist) }
          it{ is_expected.not_to be_able_to(:delete, playlist) }
        end
      end
    end
  end

  describe 'scopes' do
    describe 'by_user' do
      let(:user){ FactoryBot.create(:user) }
      let(:playlist_owner) { FactoryBot.create(:playlist, user: user) }
      let(:playlist) { FactoryBot.create(:playlist) }
      it 'returns playlists by user' do
        expect(Playlist.by_user(user)).to include(playlist_owner)
      end
      it 'does not return playlists by another user' do
        expect(Playlist.by_user(user)).not_to include(playlist)
      end
    end
    describe 'title_like' do
      let(:playlist1) { FactoryBot.create(:playlist, title: 'Moose tunes') }
      let(:playlist2) { FactoryBot.create(:playlist, title: 'My favorite by smoose') }
      let(:playlist3) { FactoryBot.create(:playlist, title: 'Favorites') }
      let(:title_filter) { 'moose' }
      it 'returns playlists with matching titles' do
        # Commented out since case insensitivity is default for mysql but not postgres
        # expect(Playlist.title_like(title_filter)).to include(playlist1)
        expect(Playlist.title_like(title_filter)).to include(playlist2)
      end
      it 'does not return playlists without matching titles' do
        expect(Playlist.title_like(title_filter)).not_to include(playlist3)
      end
    end
    describe 'with_tag' do
      let(:playlist1) { FactoryBot.create(:playlist, tags: ['Moose']) }
      let(:playlist2) { FactoryBot.create(:playlist, tags: ['Goose', 'moose']) }
      let(:playlist3) { FactoryBot.create(:playlist, tags: ['smoose', 'Goose']) }
      let(:playlist4) { FactoryBot.create(:playlist, tags: ['Goose']) }
      let(:tag_filter) { 'moose' }
      it 'returns playlists with exact matching tags' do
        # Commented out since case insensitivity is default for mysql but not postgres
        # expect(Playlist.with_tag(tag_filter)).to include(playlist1)
        expect(Playlist.with_tag(tag_filter)).to include(playlist2)
      end
      it 'does not return playlists with partial matching tag' do
        expect(Playlist.with_tag(tag_filter)).not_to include(playlist3)
      end
      it 'does not return playlists with without the tag' do
        expect(Playlist.with_tag(tag_filter)).not_to include(playlist4)
      end
    end
  end

  describe 'related items' do
    let(:user){ FactoryBot.create(:user) }
    subject(:video_master_file) { FactoryBot.create(:master_file, :with_media_object) }
    subject(:sound_master_file) { FactoryBot.create(:master_file, :with_media_object, file_format:'Sound') }
    let(:v_one_clip) { AvalonClip.new(master_file: video_master_file) }
    let(:v_two_clip) { AvalonClip.new(master_file: video_master_file) }
    let(:s_one_clip) { AvalonClip.new(master_file: sound_master_file) }

    it 'returns a list of playlist items on the current playlist related to a playlist item' do
      setup_playlist
      expect(@playlist.related_items(PlaylistItem.first).size).to eq(1)
      expect(@playlist.related_items(PlaylistItem.last).size).to eq(0)
    end
    it 'returns a list of playlist clips on the current playlist related to a playlist item' do
      setup_playlist
      expect(@playlist.related_clips(PlaylistItem.first).size).to eq(1)
      expect(@playlist.related_clips(PlaylistItem.last).size).to eq(0)
    end
    it 'returns a list of clips who start time falls within the time range of the current playlist item' do
      setup_playlist
      expect(@playlist.related_clips_time_contrained(PlaylistItem.first).size).to eq(1)
      # Move the clip outside of the time range
      v_two_clip.start_time = 2
      v_two_clip.end_time = 3
      v_two_clip.save!
      v_one_clip.end_time = 1
      v_one_clip.save!
      expect(@playlist.related_clips_time_contrained(PlaylistItem.first).size).to eq(0)
    end
    def setup_playlist
      @playlist = Playlist.new
      @playlist.user = user
      @playlist.title = 'spec test'
      @playlist.save
      annos = [v_one_clip, v_two_clip, s_one_clip]
      annos.each_with_index do |a, i|
        a.save
        @pi = PlaylistItem.new
        @pi.playlist = @playlist
        @pi.clip = a
        @pi.position = i+1
        @pi.save!
      end
    end
  end

  describe 'access_token' do
    let(:playlist) { FactoryBot.build(:playlist, visibility: Playlist::PRIVATE_WITH_TOKEN, access_token: nil) }

    it 'generates an access token on save if visibility is private-with-token and no access token exists' do
      expect(playlist.visibility).to eq Playlist::PRIVATE_WITH_TOKEN
      expect(playlist.access_token).to be_nil
      playlist.save
      expect(playlist.access_token).not_to be_nil
    end
  end

  describe '#valid_token?' do
    let(:playlist) { FactoryBot.build(:playlist, visibility: Playlist::PRIVATE_WITH_TOKEN) }
    let(:token) { playlist.access_token }

    it 'returns true for a valid token' do
      expect(playlist.valid_token?(token)).to be true
    end

    it 'returns false for an invalid token' do
      expect(playlist.valid_token?('bad-token')).to be false
    end

    it 'returns false for a playlist that is not private with token' do
      playlist.visibility = Playlist::PRIVATE
      expect(playlist.valid_token?('bad-token')).to be false
    end
  end
end
