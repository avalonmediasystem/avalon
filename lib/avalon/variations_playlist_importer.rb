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

require 'avalon/variations_mapping_service'

# A tool for converting a variations v2p file to an Avalon Playlist
# @since 5.1.0
module Avalon
  # Class for the conversion of a v2p file to an Avalon Playlist
  class VariationsPlaylistImporter
    DEFAULT_PLAYLIST_TITLE = 'Imported Variations Playlist'.freeze

    # Same as build_playlist but will attempt to save the playlist, all playlist items, clips, and markers
    def import_playlist(playlist_filename, user)
      playlist_xml = parse_playlist(File.new(playlist_filename))
      result = build_playlist(playlist_xml, user)
      Playlist.transaction do
        result[:playlist].save
        result[:playlist_items].map(&:save)
        has_error = false
        has_error ||= !result[:playlist].errors.empty?
        has_error ||= result[:playlist_items].any? { |pi| !pi.errors.empty? || !pi.clip.errors.empty? }
        raise ActiveRecord::Rollback if has_error
      end
      result
    end

    def build_playlist(playlist_xml, user)
      playlist = initialize_playlist(playlist_xml, user)
      items = playlist_xml.xpath('//ContainerStructure/Item/Chunk').collect { |chunk_xml| build_playlist_items(chunk_xml, playlist) }.flatten
      { playlist: playlist, playlist_items: items }
    end

    # Creates a playlist item from a ContainerStructure Chunk
    # @param [] The XML ContainerStructure Chunk, containing at least one content interval block, to create the playlist item from
    def build_playlist_items(chunk_xml, playlist)
      chunk_title = construct_playlist_item_title(chunk_xml)
      ci_count = chunk_xml.xpath('ContentInterval').size
      chunk_xml.xpath('ContentInterval').collect.with_index do |content_interval_xml, i|
        # If we have the use the same title multiple times because it spans on master file, increment the title
        clip_title = "#{chunk_title} - #{i + 1}" if ci_count > 1
        start_time = content_interval_xml.attr('begin')
        end_time = content_interval_xml.attr('end')
        master_file = find_master_file(content_interval_xml)
        clip = AvalonClip.new(title: clip_title, master_file: master_file, start_time: start_time, end_time: end_time)
        PlaylistItem.new(clip: clip, playlist: playlist)
      end
    end

    def build_markers(playlist_xml, playlist_items)
      # TODO: implement me!
    end

    private

    # Takes a playlist and parses it using Nokogiri
    # @param [File] playlist The playlist xml file
    # @raise [ArgumentError] When the playlist cannot be parsed or is not a playlist file
    def parse_playlist(file)
      xml = nil
      begin
        xml = Nokogiri::XML(file, &:strict)
      rescue
        raise ArgumentError, 'File is not valid XML.'
      end
      raise ArgumentError, 'File is not a playlist' unless xml.xpath('//ContainerStructure').first.present?
      xml
    end

    # Creates a new playlist to import the variations items under
    def initialize_playlist(playlist_xml, user)
      playlist = Playlist.new(user: user)
      playlist.title = construct_playlist_title(playlist_xml)
      playlist
    end

    def construct_playlist_title(playlist_xml)
      playlist_title = extract_playlist_title(playlist_xml)
      if playlist_title.blank?
        playlist_title = Avalon::VariationsPlaylistImporter::DEFAULT_PLAYLIST_TITLE # " - #{File.basename(playlist_filename)}"
        # playlist.errors.messages[:title] = "Could not determine the playlist's title, it has been given the default title"
      end
      playlist_title
    end

    # Determines the title of the playlist
    # @return [String] the playlist title or nil
    def extract_playlist_title(xml)
      xml.xpath('//ContainerStructure/@label').text
    end

    def construct_playlist_item_title(chunk_xml)
      playlist_item_title = extract_playlist_item_title(chunk_xml)
      if playlist_item_title.blank?
        playlist_item_title = '' # TODO: default playlist item title
        # playlist.errors.messages[:title] = "Could not determine the playlist's title, it has been given the default title"
      end
      playlist_item_title
    end

    # Gets the title for the playlist item from a chunk
    # @param [] the chunk to get the title from
    # @return [String] the title
    def extract_playlist_item_title(chunk_xml)
      chunk_xml.attr('label')
    end

    # lookup masterfile from Variations media object id
    def find_master_file(content_interval_xml)
      VariationsMappingService.new.find_master_file(content_interval_xml.attr('mediaRef')) rescue nil
    end
  end
end
