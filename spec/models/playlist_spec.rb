require 'spec_helper'

RSpec.describe Playlist, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:visibility) }
    it { is_expected.to validate_inclusion_of(:visibility).in_array([Playlist::PUBLIC, Playlist::PRIVATE]) }
  end

  describe 'related items' do
    subject(:video_master_file) { FactoryGirl.create(:master_file) }
    subject(:sound_master_file) { FactoryGirl.create(:master_file_sound) }
    let(:v_one_annotation) { AvalonAnnotation.new(master_file: video_master_file) }
    let(:v_two_annotation) { AvalonAnnotation.new(master_file: video_master_file) }
    let(:s_one_annotation) { AvalonAnnotation.new(master_file: sound_master_file) }

    it 'returns a list of playlist items on the current playlist related to a playlist item' do
      setup_playlist
      expect(@playlist.related_items(PlaylistItem.first).size).to eq(1)
      expect(@playlist.related_items(PlaylistItem.last).size).to eq(0)
    end
    it 'returns a list of annotations who start time falls within the time range of the current playlist item' do
      setup_playlist
      expect(@playlist.related_annotations_time_contrained(PlaylistItem.first).size).to eq(1)
      # Move the annotation outside of the time range
      v_two_annotation.start_time = 2
      v_two_annotation.end_time = 3
      v_two_annotation.save
      expect(@playlist.related_annotations_time_contrained(PlaylistItem.first).size).to eq(0)
    end
    def setup_playlist
      annos = [v_one_annotation, v_two_annotation, s_one_annotation]
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
        @pi.annotation_id = a.id
        @pi.position = pos
        @pi.save
        pos += 1
      end
    end
  end
end
