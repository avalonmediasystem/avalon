require 'spec_helper'
require 'cancan/matchers'

RSpec.describe PlaylistItem, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:playlist) }
    it { is_expected.to validate_presence_of(:annotation) }
  end

  describe 'abilities' do
    subject{ ability }
    let(:ability){ Ability.new(user) }
    let(:user){ FactoryGirl.create(:user) }
    let(:master_file) { FactoryGirl.create(:master_file) }
    let(:avalon_annotation) { FactoryGirl.create(:avalon_annotation, master_file: master_file) }
    let(:playlist_item) { FactoryGirl.create(:playlist_item, playlist: playlist, annotation: avalon_annotation) }

    context 'when owner' do
      let(:playlist) { FactoryGirl.create(:playlist, user: user) }

      it{ is_expected.to be_able_to(:create, playlist_item) }
      it{ is_expected.to be_able_to(:update, playlist_item) }
      it{ is_expected.to be_able_to(:delete, playlist_item) }
 
      context 'when master file is NOT readable by user' do
        it{ is_expected.not_to be_able_to(:read, playlist_item) }
      end

      context 'when master file is readable by user' do
        let(:media_object) { FactoryGirl.create(:published_media_object, visibility: 'public') }
        let(:master_file) { FactoryGirl.create(:master_file, mediaobject: media_object) }

        it{ is_expected.to be_able_to(:read, playlist_item) }
      end
    end

    context 'when other user' do
      let(:playlist) { FactoryGirl.create(:playlist, visibility: Playlist::PUBLIC) }

      it{ is_expected.not_to be_able_to(:create, playlist_item) }
      it{ is_expected.not_to be_able_to(:update, playlist_item) }
      it{ is_expected.not_to be_able_to(:delete, playlist_item) }

      context 'when master file is NOT readable by user' do
        it{ is_expected.not_to be_able_to(:read, playlist_item) }
      end

      context 'when master file is readable by user' do
        let(:media_object) { FactoryGirl.create(:published_media_object, visibility: 'public') }
        let(:master_file) { FactoryGirl.create(:master_file, mediaobject: media_object) }

        it{ is_expected.to be_able_to(:read, playlist_item) }
      end
    end
  end
end
