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

describe AvalonClip do
  subject(:video_master_file) { FactoryBot.create(:master_file, :with_media_object, duration: "1") }
  #subject(:sound_master_file) { FactoryBot.create(:master_file_sound) }
  let(:clip) { AvalonClip.new(master_file: video_master_file) }

  describe 'creating a clip' do
    it 'sets the master file when creating the object' do
      expect(clip.master_file.id).to eq(video_master_file.id)
    end
    it 'sets the source uri' do
      expect(clip.source).not_to be_nil
      expect { Addressable::URI.parse(clip.source) }.not_to raise_error
    end
    it 'sets default end and start times' do
      expect(clip.start_time).to eq(0)
      expect(clip.end_time).to eq(1)
    end

    it 'sets the end time to the duration of the master_file by default' do
      allow(video_master_file).to receive(:duration).and_return(100)
      clip_with_duration = AvalonClip.new(master_file: video_master_file)
      expect(clip_with_duration.end_time).to eq(100)
    end
    it 'sets the title to the master_file label by default' do
      expect(clip.title).to match(video_master_file.embed_title)
    end

    it 'loads the master_file' do
      clip.save!
      new_instance = AvalonClip.find_by(id: clip.id)
      expect(CGI::unescape(new_instance.master_file.id)).to eq(video_master_file.id)
    end

    it 'can store start and end times' do
      clip.start_time = 0.5
      clip.end_time = 0.75
      clip.save!
      clip.reload
      expect(clip.start_time).to eq(0.5)
      expect(clip.end_time).to eq(0.75)
    end
  end
  describe 'aliases for Avalon Clip' do
    describe 'aliasing content with comment' do
      it 'sets content using comment=' do
        content = 'Big Two, Little Eight'
        clip.comment = content
        clip.save!
        expect(clip.reload.content).to match(content)
      end
      it 'accesses content using comment' do
        content = '1817'
        clip.content = content
        clip.save!
        expect(clip.reload.comment).to match(content)
      end
    end
    describe 'aliasing label with title' do
      it 'sets label using title=' do
        title = 'Astrolounge'
        clip.title = title
        clip.save!
        expect(clip.reload.label).to match(title)
      end
      it 'accesses label using title' do
        title = 'Defeat You'
        clip.label = title
        clip.save!
        expect(clip.reload.title).to match(title)
      end
    end
  end
  it 'can load the master_file based on the uri' do
    mf = clip.master_file
    expect(mf.id).to eq(video_master_file.id)
  end
  describe 'selector' do
    it 'can create the selector using the start and end time' do
      allow(video_master_file).to receive(:rdf_uri).and_return(RuntimeError, 'htt://www.avalon.edu/obj')
      expect{ clip.mediafragment_uri }.not_to raise_error
    end
  end
#  describe 'solr' do
#    it 'can create a solr hash' do
#      expect(clip.to_solr.class).to eq(Hash)
#    end
#    it 'can save the clip and solrize it' do
#      expect(clip).to receive(:post_to_solr).once
#      expect { clip.save }.not_to raise_error
#    end
#    it 'can destroy clip and remove it from solr' do
#      clip.save!
#      expect(clip).to receive(:delete_from_solr).once
#      expect { clip.destroy }.not_to raise_error
#    end
#  end
  describe 'time validation' do
    describe 'negative times' do
      it 'raises an ArgumentError when start_time is negative' do
        clip.start_time = -1
        expect(clip).not_to be_valid
      end
      it 'raises an ArgumentError when end_time is negative' do
        clip.end_time = -1
        expect(clip).not_to be_valid
      end
    end
    describe 'start and end time spacing' do
      it 'raises an error when the end time preceeds the start time' do
        clip.end_time = 0
        clip.start_time = 1
        expect(clip).not_to be_valid
      end
      it 'raises an error when the end time equals the start time' do
        clip.end_time = 0
        clip.start_time = 0
        expect(clip).not_to be_valid
      end
    end
    describe 'duration' do
      subject(:video_master_file) { FactoryBot.create(:master_file, :with_media_object, duration: "8", derivatives: [derivative, derivative2]) }
      let(:derivative) { FactoryBot.create(:derivative, duration: "12") }
      let(:derivative2) { FactoryBot.create(:derivative, duration: "10") }
      it 'raises an error when end time exceeds the duration' do
        clip.end_time = 60
        expect(clip).not_to be_valid
      end
      it 'allows end times longer than master_file duration but not longer than the longest derivative' do
        clip.end_time = 12
        expect(clip).to be_valid
      end
    end
  end
  describe 'related clips' do
    let(:second_clip) { AvalonClip.new(master_file: video_master_file) }
    let!(:user) {FactoryBot.build(:user)}
    it 'returns nil when there are no related clips' do
      allow(PlaylistItem).to receive(:where).and_return([])
      expect(clip.playlist_position(1)).to be_nil
    end
    it 'returns position when there is a related clip' do
      stub_playlist
      expect(clip.playlist_position(@playlist.id)).to eq(1)
      expect(second_clip.playlist_position(@playlist.id)).to eq(2)
    end

    def stub_playlist
      user.save!
      @playlist = Playlist.new
      @playlist.title = 'whatever'
      @playlist.user = user
      @playlist.save!
      [clip, second_clip].each_with_index do |a,i|
        a.save!
        @pi = PlaylistItem.new
        @pi.playlist = @playlist
        @pi.clip = a
        @pi.position = i+1
        @pi.save!
      end
    end
  end
end
