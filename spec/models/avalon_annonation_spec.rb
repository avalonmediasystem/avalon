# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

require 'spec_helper'

describe AvalonAnnotation do
  subject(:video_master_file) { FactoryGirl.create(:master_file, duration: "1") }
  #subject(:sound_master_file) { FactoryGirl.create(:master_file_sound) }
  let(:annotation) { AvalonAnnotation.new(master_file: video_master_file) }

  describe 'creating an annotation' do
    it 'sets the master file when creating the object' do
      expect(annotation.master_file.pid).to eq(video_master_file.pid)
    end
    it 'sets the source uri' do
      expect(annotation.source).not_to be_nil
      expect { URI.parse(annotation.source) }.not_to raise_error
    end
    it 'sets default end and start times' do
      expect(annotation.start_time).to eq(0)
      expect(annotation.end_time).to eq(1)
    end

    it 'sets the end time to the duration of the master_file by default' do
      allow(video_master_file).to receive(:duration).and_return(100)
      annotation_with_duration = AvalonAnnotation.new(master_file: video_master_file)
      expect(annotation_with_duration.end_time).to eq(100)
    end
    it 'sets the title to the master_file label by default' do
      expect(annotation.title).to match(video_master_file.embed_title)
    end

    it 'loads the master_file' do
      annotation.save!
      new_instance = AvalonAnnotation.find_by(id: annotation.id)
      expect(new_instance.master_file.pid).to eq(video_master_file.pid)
    end

    it 'can store start and end times' do
      annotation.start_time = 0.5
      annotation.end_time = 0.75
      annotation.save!
      annotation.reload
      expect(annotation.start_time).to eq(0.5)
      expect(annotation.end_time).to eq(0.75)
    end
  end
  describe 'aliases for Avalon Annotation' do
    describe 'aliasing content with comment' do
      it 'sets content using comment=' do
        content = 'Big Two, Little Eight'
        annotation.comment = content
        annotation.save!
        expect(annotation.reload.content).to match(content)
      end
      it 'accesses content using comment' do
        content = '1817'
        annotation.content = content
        annotation.save!
        expect(annotation.reload.comment).to match(content)
      end
    end
    describe 'aliasing label with title' do
      it 'sets label using title=' do
        title = 'Astrolounge'
        annotation.title = title
        annotation.save!
        expect(annotation.reload.label).to match(title)
      end
      it 'accesses label using title' do
        title = 'Defeat You'
        annotation.label = title
        annotation.save!
        expect(annotation.reload.title).to match(title)
      end
    end
  end
  it 'can load the master_file based on the uri' do
    mf = annotation.master_file
    expect(mf.pid).to eq(video_master_file.pid)
  end
  describe 'selector' do
    it 'can create the selector using the start and end time' do
      video_master_file.stub(:rdf_uri).and_return(RuntimeError, 'htt://www.avalon.edu/obj')
      expect{ annotation.mediafragment_uri }.not_to raise_error
    end
  end
  describe 'solr' do
    it 'can create a solr hash' do
      expect(annotation.to_solr.class).to eq(Hash)
    end
    it 'can save the annotation and solrize it' do
      expect(annotation).to receive(:post_to_solr).once
      expect { annotation.save }.not_to raise_error
    end
    it 'can destroy annotation and remove it from solr' do
      annotation.save!
      expect(annotation).to receive(:delete_from_solr).once
      expect { annotation.destroy }.not_to raise_error
    end
  end
  describe 'time validation' do
    describe 'negative times' do
      it 'raises an ArgumentError when start_time is negative' do
        annotation.start_time = -1
        expect(annotation).not_to be_valid
      end
      it 'raises an ArgumentError when end_time is negative' do
        annotation.end_time = -1
        expect(annotation).not_to be_valid
      end
    end
    describe 'start and end time spacing' do
      it 'raises an error when the end time preceeds the start time' do
        annotation.end_time = 0
        annotation.start_time = 1
        expect(annotation).not_to be_valid
      end
      it 'raises an error when the end time equals the start time' do
        annotation.end_time = 0
        annotation.start_time = 0
        expect(annotation).not_to be_valid
      end
    end
    describe 'duration' do
      it 'raises an error when end time exceeds the duration' do
        annotation.master_file.duration = '8'
        annotation.master_file.save!
        annotation.end_time = 60
        expect(annotation).not_to be_valid
      end
    end
  end
  describe 'related annotations' do
    let(:second_annotation) { AvalonAnnotation.new(master_file: video_master_file) }
    let!(:user) {FactoryGirl.build(:user)}
    it 'returns nil when there are no related annotations' do
      allow(PlaylistItem).to receive(:where).and_return([])
      expect(annotation.playlist_position(1)).to be_nil
    end
    it 'returns position when there is a related annotation' do
      #byebug
      stub_playlist
      expect(annotation.playlist_position(@playlist.id)).to eq(1)
      expect(second_annotation.playlist_position(@playlist.id)).to eq(2)
    end

    def stub_playlist
      user.save!
      @playlist = Playlist.new
      @playlist.title = 'whatever'
      @playlist.user_id = User.last.id
      @playlist.save!
      pos = 1
      [annotation, second_annotation].each do |a|
        a.save!
        @pi = PlaylistItem.new
        @pi.playlist_id = @playlist.id
        @pi.annotation_id = a.id
        @pi.position = pos
        @pi.save!
        pos += 1
      end
    end
  end
end
