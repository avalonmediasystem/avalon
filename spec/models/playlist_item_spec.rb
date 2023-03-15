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
require 'cancan/matchers'

RSpec.describe PlaylistItem, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:playlist) }
    it { is_expected.to validate_presence_of(:clip) }
  end

  describe 'abilities' do
    subject{ ability }
    let(:ability){ Ability.new(user) }
    let(:user){ FactoryBot.create(:user) }
    let(:master_file) { FactoryBot.create(:master_file, :with_media_object) }
    let(:avalon_clip) { FactoryBot.create(:avalon_clip, master_file: master_file) }
    let(:playlist_item) { FactoryBot.create(:playlist_item, playlist: playlist, clip: avalon_clip) }

    context 'when owner' do
      let(:playlist) { FactoryBot.create(:playlist, user: user) }
      let(:user) { FactoryBot.create(:administrator) }

      it{ is_expected.to be_able_to(:manage, playlist_item) }
      it{ is_expected.to be_able_to(:create, playlist_item) }
      it{ is_expected.to be_able_to(:read, playlist_item) }
      it{ is_expected.to be_able_to(:update, playlist_item) }
      it{ is_expected.to be_able_to(:delete, playlist_item) }
    end

    context 'when owner' do
      let(:playlist) { FactoryBot.create(:playlist, user: user) }

      it{ is_expected.to be_able_to(:create, playlist_item) }
      it{ is_expected.to be_able_to(:update, playlist_item) }
      it{ is_expected.to be_able_to(:delete, playlist_item) }

      context 'when master file is NOT readable by user' do
        it{ is_expected.not_to be_able_to(:read, playlist_item) }
      end

      context 'when master file is readable by user' do
        let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
        let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }

        it{ is_expected.to be_able_to(:read, playlist_item) }
      end
    end

    context 'when other user' do
      let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

      it{ is_expected.not_to be_able_to(:create, playlist_item) }
      it{ is_expected.not_to be_able_to(:update, playlist_item) }
      it{ is_expected.not_to be_able_to(:delete, playlist_item) }

      context 'when master file is NOT readable by user' do
        it{ is_expected.not_to be_able_to(:read, playlist_item) }
      end

      context 'when master file is readable by user' do
        let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
        let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }

        it{ is_expected.to be_able_to(:read, playlist_item) }
      end
    end

    context 'when other user' do
      let(:ability){ Ability.new(user) }
      let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

      it{ is_expected.not_to be_able_to(:create, playlist_item) }
      it{ is_expected.not_to be_able_to(:update, playlist_item) }
      it{ is_expected.not_to be_able_to(:delete, playlist_item) }

      context 'when master file is NOT readable by public' do
        it{ is_expected.not_to be_able_to(:read, playlist_item) }
      end

      context 'when master file is readable by public' do
        let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
        let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }

        it{ is_expected.to be_able_to(:read, playlist_item) }
      end
    end
  end

  describe '#duplicate!' do
    let(:master_file) { FactoryBot.create(:master_file, :with_media_object) }
    let(:playlist_item) { FactoryBot.create(:playlist_item, playlist: playlist, clip: avalon_clip) }
    let(:avalon_clip) { FactoryBot.create(:avalon_clip, master_file: master_file) }
    let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

    it 'it duplicates an item' do
      new_item = playlist_item.duplicate!
      expect(new_item.id).not_to eq playlist_item.id
      expect(new_item.playlist_id).to eq playlist_item.playlist_id
      expect(new_item.clip_id).not_to eq playlist_item.clip_id
      expect(new_item.persisted?).to eq true
    end
  end
end
