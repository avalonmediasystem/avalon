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
  before(:all) do
    Avalon::Configuration['variations'] = { 'media_object_id_map_file' => 'spec/fixtures/variations_playlists/variations_media_object_id_map.yml' }
    Avalon::VariationsMappingService::MEDIA_OBJECT_ID_MAP = begin
                                                              YAML.load_file(Avalon::Configuration['variations']['media_object_id_map_file']).freeze
                                                            rescue
                                                              {}
                                                            end
  end

  let(:master_file_fixture_info) do
    {
      'ABU3086A' => { duration: '3509000', mo_title: 'Electro acoustic music classics.' },
      'AAW7788B' => { duration: '4094293', mo_title: 'St. Luke\'s Passion ; Threnody ; Polymorphy ; String quartet ; Psalms of David ; Dimensions of time and silence' },
      'ABF5897A' => { duration: '3384266', mo_title: 'Early works' },
      'VAB7265A' => { duration: '3731599', mo_title: 'From the kitchen archives no. 2 Steve Reich and musicians, live 1977.' },
      'ABD4563A' => { duration: '1965666', mo_title: 'Nixon in China' },
      'ADU7077A' => { duration: '3649026', mo_title: 'Amériques Offrandes ; Hyperprism ; Octandre ; Arcana' }
    }
  end
  let(:master_file_fixtures) do
    master_files = []
    master_file_fixture_info.each_pair do |id, info|
      media_object = FactoryGirl.create(:media_object, title: info[:mo_title])
      master_file = FactoryGirl.create(:master_file, duration: info[:duration], label: id, mediaobject: media_object)
      master_file.DC.identifier += [id]
      master_file.save
      master_files << master_file.reload
    end
    master_files
  end

  subject { Avalon::VariationsPlaylistImporter.new }
  let(:fixture) { File.new(full_fixture_path('T351.v2p')) }
  let(:user) { FactoryGirl.create(:user) }

  describe '#import_playlist' do
    it 'returns a playlist and playlist items' do
      playlist = subject.import_playlist(fixture, user)
      expect(playlist).not_to be_blank
      expect(playlist.items).not_to be_blank
      expect(playlist.items.collect(&:marker).flatten).not_to be_blank
    end

    it 'attempts to save the playlist, items, and markers and reports errors' do
      playlist = subject.import_playlist(fixture, user)
      expect(playlist.errors).not_to be_blank
      expect(playlist.persisted?).to be_falsy
      expect(playlist.items.any?(&:persisted?)).to be_falsy
      expect(playlist.items.collect(&:clip).flatten.any?(&:persisted?)).to be_falsy
      expect(playlist.items.collect(&:marker).flatten.any?(&:persisted?)).to be_falsy
    end

    context 'with skip errors' do
      let(:master_file_notis_id) { 'ADU7077A' }
      before do
        mf_info = master_file_fixture_info[master_file_notis_id]
        media_object = FactoryGirl.create(:media_object, title: mf_info[:mo_title])
        master_file = FactoryGirl.create(:master_file, duration: mf_info[:duration], label: master_file_notis_id, mediaobject: media_object)
        master_file.DC.identifier += [master_file_notis_id]
        master_file.save
      end

      it 'returns only objects that successfully saved' do
        playlist = subject.import_playlist(fixture, user, true)
        expect(playlist.persisted?).to be_truthy
        expect(playlist.items.count).to eq 1
        expect(playlist.items.all?(&:persisted?)).to be_truthy
        expect(playlist.items.all? { |pi| pi.clip.persisted? }).to be_truthy
        expect(playlist.items.first.marker.count).to eq 2
        expect(playlist.items.first.marker.all?(&:persisted?)).to be_truthy
      end
    end

    context 'with all fixtures' do
      before do
        master_file_fixtures
      end

      it 'successfully saves the whole playlist tree' do
        playlist = subject.import_playlist(fixture, user, true)
        expect(playlist.persisted?).to be_truthy
        expect(playlist.items.count).to eq 7
        expect(playlist.items.all?(&:persisted?)).to be_truthy
        expect(playlist.items.all? { |pi| pi.clip.persisted? }).to be_truthy
        expect(playlist.items.collect(&:marker).flatten.size).to eq 3
        expect(playlist.items.collect(&:marker).flatten.all?(&:persisted?)).to be_truthy
      end
    end

    context 'with invalid playlist xml' do
      let(:fixture) { File.new(full_fixture_path('T351-broken.v2p')) }
      it 'raises an ArgumentError when it cannot parse a playlist' do
        expect { subject.import_playlist(fixture, user) }.to raise_error(ArgumentError)
      end
    end
    context 'with valid xml that is not a playlist' do
      let(:fixture) { File.new(full_fixture_path('not-a-playlist.xml')) }
      xit 'raises an ArgumentError when there is no ContainerStructure structure object' do
        expect { subject.import_playlist(fixture, user) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#build_playlist' do
    let(:fixture_xml) { Nokogiri::XML(fixture, &:strict) }
    let(:playlist) { subject.build_playlist(fixture_xml, user) }

    it 'returns playlist and items' do
      expect(playlist).not_to be_blank
    end

    it 'sets the title' do
      expect(playlist.title).to eq 'T351 Module 3 Week 12'
    end

    context 'with unreadable ContainerStructure label' do
      let(:fixture) { File.new(full_fixture_path('unreadable-playlist-title.v2p')) }
      it 'provides a default title if necessary' do
        expect(playlist.title).to eq Avalon::VariationsPlaylistImporter::DEFAULT_PLAYLIST_TITLE
      end
    end

    it 'sets the user' do
      expect(playlist.user).to eq user
    end

    it 'creates playlist items' do
      expect(playlist.items.to_a.size).to eq 7
    end

    it 'checks if playlist title is string' do
      expect(playlist.items.first.title). to be_a(String)
    end
    it 'finds particular title' do
      expect(playlist.items.map(&:title)).to include 'Varèse, Hyperprism (1923)'
    end

    it 'finds particular start time' do
      expect(playlist.items.first.start_time).to eq 1_874_827.0
    end

    it 'doesnt find title which is not there' do
      expect(playlist.items.map(&:title)).not_to include 'Test title for Avalon'
    end

    it 'doesnt find start time which is not present' do
      expect(playlist.items.first.start_time).not_to eq 300_000.0
    end

    it 'creates playlist markers' do
      expect(playlist.items.collect { |pi| pi.marker.to_a.size }.sum).to eq 3
    end

    it 'finds particular marker title' do
      expect(playlist.items.first.marker.map(&:title)).to include 'Varèse, Hyperprism (1923) 1:25'
    end

    it 'doesnt find title which doesnt have marker' do
      expect(playlist.items.first.marker.map(&:title)).not_to include 'Reich, Early Works, Clapping Music'
    end

    it 'finds offset' do
      # Got this value after running the test
      expect(playlist.items.first.marker.first.start_time).to eq 1959827.0
    end
  end

  describe'#build_markers' do
    let(:bookmark_xml) { Nokogiri::XML(fixture, &:strict)}
    let(:marker) { subject.build_marker(bookmark_xml, [playlist_item])}
    let(:playlist_item) {FactoryGirl.create(:playlist_item)}

    it 'returns marker and items' do
      expect(marker).not_to be_blank
    end
  end

end

def full_fixture_path(filename)
  File.expand_path("../../../fixtures/variations_playlists/#{filename}", __FILE__)
end
