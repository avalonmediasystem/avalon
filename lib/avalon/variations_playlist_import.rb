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

# A tool for converting a variations v2p file to an Avalon Playlist
# @since 5.1.0
module Avalon
  # Class for the conversion of a v2p file to an Avalon Playlist
  class VariationsPlaylistImport
    @playlist = ''
    @errors_and_alerts = []
    @objects_created = []
    @avalon_playlist = nil

    # Takes a playlist and parses it using Nokogiri
    # @param [String] playlist The entirity of the playlist
    # @raise [ArgumentError] When the playlist cannot be parsed
    def parse_playlist(playlist)
      @playlist = Nokogiri::XML(playlist, &:strict)
    rescue
      raise ArgumentError, 'Provided Playlist lacks valid XML.'
    end

    # Determines the title of the playlist
    # @raise [RuntimeError] raised if there is no valid ContainerStructure (the parent object for variations playlist items)
    # @return [String] the playlist title or the default value: Imported Vatiations Playlist
    def playlist_title
      title = nil
      begin
        title = @playlist.xpath('//ContainerStructure').first.attribute('label').text
      rescue
        raise RuntimeError if @playlist.xpath('//ContainerStructure').empty?
        title = 'Imported Vatiations Playlist'
        @errors_and_alerts << { type: :alert, message: "Could not determine the playlist's title, it has been given the default title: Imported Vatiations Playlist" }
      end
      title
    end

    # Creates a new playlist to import the variations items under
    # @param [User] the user to create for the playlist
    # @raise [ActiveRecord::RecordInvalid] if the playlist cannot be saved
    def create_playlist(user)
      @avalon_playlist = Playlist.new
      @avalon_playlist.title = playlist_title
      @avalon_playlist.user = user
      @avalon_playlist.save!
      @avalon_playlist.reload
      @objects_created << @avalon_playlist
    end

    # Creates a playlist item from a v2p Chunk
    # @param [] The xml chunk, containing at least one content interval block, to create the playlist item from
    def create_playlist_item(chunk)
      chunk_title = playlistitem_title(chunk)
      count = 0
      chunk.xpath('ContentInterval').each do |content_interval|
        # If we have the use the same title multiple times because it spans on master file, increment the title
        item_title = chunk_title
        count += 1
        item_title << " #{count}" if chunk.xpath('ContentInterval').size > 1
        start_time = content_interval.attribute('begin')
        end_time = content_interval.attribute('end')
        referenced_file = content_interval.attribute('mediaRef').text
        master_file = #TODO: map referenced file to a master_file
        #TODO: create a new playlist item using the above and @avalon_playlist
      end
    end

    # Gets the title for the playlist item from a chunk
    def playlistitem_title(chunk)
      # TODO: Handle errors when there is no label attribute or the text cannot be read
      # TODO: Set a default if the label text is nil
      chunk.attribute('label').text
    end
  end
end
