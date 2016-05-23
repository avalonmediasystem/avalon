require 'spec_helper'

RSpec.describe PlaylistItem, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:playlist) }
    it { is_expected.to validate_presence_of(:annotation) }
  end

  describe 'abilities' do
    subject{ ability }
    let(:ability){ Ability.new(user) }
    let(:user){ FactoryGirl.create(:user) }

    context 'when owner' do
      let(:playlist) { FactoryGirl.create(:playlist, user: user) }
      let(:playlist_item) { FactoryGirl.create(:playlist_item, playlist: playlist) }

      it{ is_expected.to be_able_to(:manage, playlist_item) }
      it{ is_expected.to be_able_to(:create, playlist_item) }
      it{ is_expected.to be_able_to(:read, playlist_item) }
      it{ is_expected.to be_able_to(:update, playlist_item) }
      it{ is_expected.to be_able_to(:delete, playlist_item) }
    end

    context 'when other user' do
      let(:playlist) { FactoryGirl.create(:playlist, visibility: Playlist::PUBLIC) }
      let(:playlist_item) { FactoryGirl.create(:playlist_item, playlist: playlist) }

      it{ is_expected.not_to be_able_to(:manage, playlist_item) }
      it{ is_expected.not_to be_able_to(:create, playlist_item) }
      it{ is_expected.to be_able_to(:read, playlist_item) }
      it{ is_expected.not_to be_able_to(:update, playlist_item) }
      it{ is_expected.not_to be_able_to(:delete, playlist_item) }
    end
  end

end
