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
require 'avalon/variations_playlist_import'

describe Avalon::VariationsPlaylistImport do
  before :all do
    @good_fixture = full_fixture_path('T351')
    @invalid_xml_fixture = full_fixture_path('T351-broken')
  end

  before :each do
    @playlist_parser = Avalon::VariationsPlaylistImport.new
  end

  describe 'parsing a playlist' do
    it 'can parse a playlist' do
      expect(@playlist_parser.parse_playlist(IO.read(@good_fixture)).class).to eq(Nokogiri::XML::Document)
    end
    it 'raises an ArgumentError when it cannot parse a playlist' do
      expect { @playlist_parser.parse_playlist(IO.read(@invalid_xml_fixture)) }.to raise_error(ArgumentError)
    end
  end
  describe 'playlist title' do
    it 'can determine the playlist title' do
      @playlist_parser.parse_playlist(IO.read(@good_fixture))
      expect(@playlist_parser.playlist_title).to match('T351 Module 3 Week 12')
    end
    xit 'returns the default value when the playlist ContainerStructure exists but the label attribute cannot be read' do
      # You'll need to create an xml snippet that has a ContainerStructure like the T351 fixture but does not have the label attribute set
      # Then run the test above (only pass in your xml snippet and expect it to match the given default title (see the actual function being tested)
    end
    xit 'raises a runtime error when there is no ContainerStructure structure object' do
      # Same as above, but this time no ContainerStructure block at all
      # when expecting errors use expect { } not expect ( )
      # expect { foo }.to raise_error(ERROR_TYPE)
    end
  end
  describe 'creating a playlist' do
    before :each do
      allow(@playlist_parser).to receive(:playlist_title).and_return('Go Blue')
      # TODO: Replace me with a FactoryGirl for User
      @user = User.new
      @user.username = 'Victor'
      @user.email = 'Valiant'
      @user.save
      @user.reload
    end
    it 'can create a playlist' do
      expect { @playlist_parser.create_playlist(@user) }.not_to raise_error
    end
    xit 'raises a ActiveRecord::RecordInvalid when it cannot save a playlist' do
      # Alter the @user that is no longer points to a valid user
      expect { @playlist_parser.create_playlist(@user) }.to raise_error(ActiveRecord::RecordInvalid)
    end
    xit 'adds a newly created to the @objects_created playlist' do
      # Make a new playlist and ensure it on the  @objects_created list
    end
  end
  describe 'creating playlist items' do
    # TODO Create a playlist via FactoryGirl for all the playlist items
    # TODO Set this playlist to the class variable @avalon_playlist
    xit 'can create a playlist item' do
      # Don't try to get me running yet, the mapper hasn't been written so I can't work
    end
  end
end

def full_fixture_path(filename)
  File.expand_path("../../../fixtures/variations_playlists/#{filename}.v2p", __FILE__)
end
