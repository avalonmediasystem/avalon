require 'spec_helper'
require 'cancan/matchers'

RSpec.describe Playlist, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:visibility) }
    it { is_expected.to validate_inclusion_of(:visibility).in_array([Playlist::PUBLIC, Playlist::PRIVATE]) }
  end

  describe 'abilities' do
    subject{ ability }
    let(:ability){ Ability.new(user) }
    let(:user){ FactoryGirl.create(:user) }

    context 'when owner' do
      let(:playlist) { FactoryGirl.create(:playlist, user: user) }

      it{ is_expected.to be_able_to(:manage, playlist) }
      it{ is_expected.to be_able_to(:create, playlist) }
      it{ is_expected.to be_able_to(:read, playlist) }
      it{ is_expected.to be_able_to(:update, playlist) }
      it{ is_expected.to be_able_to(:delete, playlist) }
    end

    context 'when other user' do
      let(:playlist) { FactoryGirl.create(:playlist, visibility: Playlist::PUBLIC) }

      it{ is_expected.not_to be_able_to(:manage, playlist) }
      it{ is_expected.not_to be_able_to(:create, playlist) }
      it{ is_expected.to be_able_to(:read, playlist) }
      it{ is_expected.not_to be_able_to(:update, playlist) }
      it{ is_expected.not_to be_able_to(:delete, playlist) }
    end
  end

  describe 'related items' do
    subject(:video_master_file) { FactoryGirl.create(:master_file) }
    subject(:sound_master_file) { FactoryGirl.create(:master_file_sound) }
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
      annos = [v_one_clip, v_two_clip, s_one_clip]
      annos.each do |a|
        a.save
      end
      @playlist = Playlist.new
      @playlist.user_id = User.last.id
      @playlist.title = 'spec test'
      @playlist.save
      pos = 1
      annos.each do |a|
        @pi = PlaylistItem.new
        @pi.playlist_id = @playlist.id
        @pi.clip_id = a.id
        @pi.position = pos
        @pi.save!
        pos += 1
      end
    end
  end
end
