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
  subject(:video_master_file) { FactoryGirl.create(:master_file) }
  #subject(:sound_master_file) { FactoryGirl.create(:master_file_sound) }
  let(:annotation) { AvalonAnnotation.new(master_file: video_master_file) }

  describe 'creating an annotation' do
    before :each do
      annotation = AvalonAnnotation.new(master_file: video_master_file)
    end
    it 'sets the master file when creating the object' do
      expect(annotation.master_file.id).to eq(video_master_file.id)
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
      expect(annotation.title).to match(video_master_file.label)
    end
  end
  describe 'aliases for Avalon Annotation' do
    describe 'aliasing content with comment' do
      it 'sets content using comment=' do
        content = 'Big Two, Little Eight'
        annotation.comment = content
        expect(annotation.content).to match(content)
      end
      it 'accesses content using comment' do
        content = '1817'
        annotation.content = content
        expect(annotation.comment).to match(content)
      end
    end
    describe 'aliasing label with title' do
      it 'sets label using title=' do
        title = 'Astrolounge'
        annotation.title = title
        expect(annotation.label).to match(title)
      end
      it 'accesses label using title' do
        title = 'Defeat You'
        annotation.label = title
        expect(annotation.title).to match(title)
      end
    end
  end
  it 'can load the master_file based on the uri' do
    mf = annotation.init_masterfile
    expect(mf.id).to eq(video_master_file.id)
  end
  describe 'selector' do
    it 'can create the selector using the start and end time' do
      video_master_file.stub(:rdf_uri).and_return(RuntimeError, 'htt://www.avalon.edu/obj')
      expect{ annotation.mediafragment_uri }.not_to raise_error
    end
  end
  it 'can create a solr hash' do
    expect(annotation.to_solr.class).to eq(Hash)
  end
end
