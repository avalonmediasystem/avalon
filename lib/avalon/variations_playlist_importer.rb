# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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
    def import_playlist(playlist_file, user, skip_errors = false)
      playlist_xml = parse_playlist(playlist_file)
      playlist = build_playlist(playlist_xml, user)
      if skip_errors
        # Clean out invalid objects
        playlist.items.each { |pi| pi.marker = pi.marker.select(&:valid?) }
        playlist.items = playlist.items.select { |pi| pi.valid? && pi.clip.valid? }
        playlist.save
      else
        has_error = false
        has_error ||= playlist.invalid?
        has_error ||= playlist.items.any? { |pi| pi.invalid?  || pi.clip.invalid? }
        has_error ||= playlist.items.any? { |pi| pi.marker.any? { |m| m.invalid? } }
        playlist.save unless has_error
      end
      playlist
    end

    def build_playlist(playlist_xml, user)
      playlist = initialize_playlist(playlist_xml, user)
      playlist.items = playlist_xml.xpath('//ContainerStructure/Item/Chunk').collect { |chunk_xml| build_playlist_items(chunk_xml, playlist) }.flatten
      markers = playlist_xml.xpath('//BookmarkTree/PlaylistBookmark').collect { |bookmark_xml| build_marker(bookmark_xml, playlist.items) }
      markers.each { |m| m.playlist_item.marker += [m] if m.playlist_item } # Make the playlist items aware of the markers
      playlist
    end

    # Creates a playlist item from a ContainerStructure Chunk
    # @param [] The XML ContainerStructure Chunk, containing at least one content interval block, to create the playlist item from
    def build_playlist_items(chunk_xml, playlist)
      chunk_title = construct_playlist_item_title(chunk_xml)
      ci_count = chunk_xml.xpath('ContentInterval').size
      chunk_xml.xpath('ContentInterval').collect.with_index do |content_interval_xml, i|
        # If we have the use the same title multiple times because it spans on master file, increment the title
        clip_title = chunk_title
        clip_title << " - #{i + 1}" if ci_count > 1
        start_time = content_interval_xml.attr('begin')
        end_time = content_interval_xml.attr('end')
        master_file = find_master_file(content_interval_xml)
        clip = AvalonClip.new(title: clip_title, master_file: master_file, start_time: start_time, end_time: end_time)
        PlaylistItem.new(clip: clip, playlist: playlist)
      end
    end

    def build_marker(bookmark_xml, playlist_items)
      marker_title = construct_marker_title(bookmark_xml)
      playlist_offset = bookmark_xml.xpath('Offset').text.to_f
      playlist_item = find_associated_playlist_item(playlist_offset, playlist_items)
      start_time = construct_marker_start_time(playlist_offset, playlist_item, playlist_items)
      master_file = playlist_item.clip.master_file rescue nil
      AvalonMarker.new(title: marker_title, start_time: start_time, playlist_item: playlist_item, master_file: master_file)
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
      # AvalonClip will supply a defualt title from the masterfile if none is found here
      # if playlist_item_title.blank?
      #   playlist_item_title = '' # TODO: default playlist item title
      # end
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
      VariationsMappingService.new.find_master_file(content_interval_xml.attr('mediaRef'))
    rescue StandardError => e
      Rails.logger.warn "VariationsPlaylistImporter: Error finding MasterFile: #{e.message}"
      return nil
    end

    def construct_marker_title(bookmark_xml)
      marker_title = extract_marker_title(bookmark_xml)
      # AvalonMarker will supply a defualt title from the masterfile if none is found here
      # if marker_title.blank?
      #   marker_title = '' # TODO: default marker title
      # end
      marker_title
    end

    def extract_marker_title(bookmark_xml)
      bookmark_xml.attr('name')
    end

    def find_associated_playlist_item(playlist_offset, playlist_items)
      offsets = playlist_offsets(playlist_items)
      playlist_item_offset = offsets.reverse.bsearch { |x| x <= playlist_offset }
      item_index = offsets.index(playlist_item_offset)
      playlist_items.at(item_index)
    rescue
      nil
    end

    def construct_marker_start_time(playlist_offset, associated_playlist_item, playlist_items)
      offsets = playlist_offsets(playlist_items)
      item_index = playlist_items.index(associated_playlist_item)
      playlist_item_offset = playlist_offset - offsets[item_index]
      playlist_item_offset + associated_playlist_item.start_time
    rescue
      -1
    end

    def playlist_offsets(playlist_items)
      offsets = [0]
      playlist_items.each { |pi| offsets << offsets.last + (pi.end_time - pi.start_time) }
      offsets.slice(0..-2)
    rescue
      []
    end
  end
end
