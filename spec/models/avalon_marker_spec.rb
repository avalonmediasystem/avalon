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

describe AvalonMarker, type: :model do
  describe 'abilities' do
    subject { ability }
    let(:ability) { Ability.new(user) }
    let(:user) { FactoryBot.create(:user) }
    let(:master_file) { FactoryBot.create(:master_file, :with_media_object) }
    let(:avalon_clip) { FactoryBot.create(:avalon_clip, master_file: master_file) }
    let(:playlist_item) { FactoryBot.create(:playlist_item, playlist: playlist, clip: avalon_clip) }
    let(:avalon_marker) { FactoryBot.create(:avalon_marker, playlist_item: playlist_item, master_file: master_file) }

    context 'when owner' do
      let(:playlist) { FactoryBot.create(:playlist, user: user) }
      let(:user) { FactoryBot.create(:administrator) }

      it { is_expected.to be_able_to(:manage, avalon_marker) }
      it { is_expected.to be_able_to(:create, avalon_marker) }
      it { is_expected.to be_able_to(:read, avalon_marker) }
      it { is_expected.to be_able_to(:update, avalon_marker) }
      it { is_expected.to be_able_to(:delete, avalon_marker) }
    end


    context 'when owner' do
      let(:playlist) { FactoryBot.create(:playlist, user: user) }

      it { is_expected.to be_able_to(:create, avalon_marker) }
      it { is_expected.to be_able_to(:update, avalon_marker) }
      it { is_expected.to be_able_to(:delete, avalon_marker) }

      context 'when master file is NOT readable by user' do
        it { is_expected.not_to be_able_to(:read, avalon_marker) }
      end

      context 'when master file is readable by user' do
        let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
        let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }

        it { is_expected.to be_able_to(:read, avalon_marker) }
      end
    end

    context 'when other user' do
      let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

      it { is_expected.not_to be_able_to(:create, avalon_marker) }
      it { is_expected.not_to be_able_to(:update, avalon_marker) }
      it { is_expected.not_to be_able_to(:delete, avalon_marker) }

      context 'when master file is NOT readable by user' do
        it { is_expected.not_to be_able_to(:read, avalon_marker) }
      end

      context 'when master file is readable by user' do
        let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
        let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }

        it { is_expected.to be_able_to(:read, avalon_marker) }

        context 'when playlist is share by link' do
          let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PRIVATE_WITH_TOKEN) }

          context 'when token is given' do
            let(:ability) { Ability.new(user, {playlist_token: playlist.access_token}) }
            it { is_expected.to be_able_to(:read, avalon_marker) }
          end

          context 'when token is not given' do
            it { is_expected.not_to be_able_to(:read, avalon_marker) }
          end
        end
      end
    end

    context 'when not logged in' do
      let(:ability) { Ability.new(nil) }
      let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PUBLIC) }

      it { is_expected.not_to be_able_to(:create, avalon_marker) }
      it { is_expected.not_to be_able_to(:update, avalon_marker) }
      it { is_expected.not_to be_able_to(:delete, avalon_marker) }

      context 'when master file is NOT readable by public' do
        it { is_expected.not_to be_able_to(:read, avalon_marker) }
      end

      context 'when master file is readable by public' do
        let(:media_object) { FactoryBot.create(:published_media_object, visibility: 'public') }
        let(:master_file) { FactoryBot.create(:master_file, media_object: media_object) }

        it { is_expected.to be_able_to(:read, avalon_marker) }

        context 'when playlist is share by link' do
          let(:playlist) { FactoryBot.create(:playlist, visibility: Playlist::PRIVATE_WITH_TOKEN) }

          context 'when token is given' do
            let(:ability) { Ability.new(user, {playlist_token: playlist.access_token}) }
            it { is_expected.to be_able_to(:read, avalon_marker) }
          end

          context 'when token is not given' do
            it { is_expected.not_to be_able_to(:read, avalon_marker) }
          end
        end
      end
    end
  end
end
