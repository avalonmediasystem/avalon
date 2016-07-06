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
require 'avalon/variations_playlist_importer'

describe Avalon::VariationsPlaylistImporter do
  subject { Avalon::VariationsPlaylistImporter.new }
  let(:fixture) { full_fixture_path('T351.v2p') }
  let(:fixture_file) { File.new(fixture) }
  let(:user) { FactoryGirl.create(:user) }

  describe '#import_playlist!' do
    it 'returns a playlist' do
      expect(subject.import_playlist!(fixture, user)).to be_a Playlist
    end

    context 'with invalid playlist xml' do
      let(:fixture) { full_fixture_path('T351-broken.v2p') }
      it 'raises an ArgumentError when it cannot parse a playlist' do
        expect { subject.import_playlist!(fixture, user) }.to raise_error(ArgumentError)
      end
    end
    context 'with valid xml that is not a playlist' do
      let(:fixture) { full_fixture_path('not-a-playlist.xml') }
      xit 'raises an ArgumentError when there is no ContainerStructure structure object' do
        expect { subject.import_playlist!(fixture, user) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#build_playlist' do
    let(:fixture_xml) { Nokogiri::XML(fixture_file, &:strict) }
    let(:result) { subject.build_playlist(fixture_xml, user) }
    let(:result_playlist) { result[:playlist] }
    let(:result_playlist_items) { result[:playlist_items] }

    it 'returns playlist and items' do
      expect(result).to be_a Hash
    end

    it 'sets the title' do
      expect(result_playlist.title).to eq 'T351 Module 3 Week 12'
    end

    context 'with unreadable ContainerStructure label' do
      let(:fixture) { full_fixture_path('unreadable-title.v2p') }
      xit 'provides a default title if necessary' do
        expect(result_playlist.title).to eq Avalon::VariationsPlaylistImporter::DEFAULT_PLAYLIST_TITLE
      end
    end

    it 'sets the user' do
      expect(result_playlist.user).to eq user
    end

    it 'creates playlist items' do
      expect(result_playlist_items.count).to eq 7
    end
  end
end

def full_fixture_path(filename)
  File.expand_path("../../../fixtures/variations_playlists/#{filename}", __FILE__)
end
