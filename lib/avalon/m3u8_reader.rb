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

require 'open-uri'
require 'uri'

module Avalon
  class M3U8Reader
    attr_reader :playlist

    def self.read(io, recursive: true)
      if io.is_a?(IO)
        new(io.read, recursive: recursive)
      elsif io.is_a?(String)
        if io =~ /^https?:/
          open(io, "Referer" => Rails.application.routes.url_helpers.root_url) { |resp| new(resp, Addressable::URI.parse(io), recursive: recursive) }
        elsif io =~ /\.m3u8?$/i
          new(File.read(io), io, recursive: recursive)
        else
          new(io, recursive: recursive)
        end
      end
    end

    def initialize(playlist, base = '', recursive: true)
      @base = base
      @playlist = { files: [], playlists: [] }
      tags = {}
      playlist.lines.each do |l|
        line = l.chomp
        if line =~ /^#EXTM3U/
          # ignore
        elsif line =~ /^#EXT-X-(.+):(.+)$/
          value = Regexp.last_match(2)
          tag = Regexp.last_match(1).downcase.tr('-', "_")
          @playlist[tag] = value
        elsif line =~ /^#EXTINF:(.+),(.*)$/
          tags[:duration] = Regexp.last_match(1).to_f
          tags[:title] = Regexp.last_match(2)
        elsif line =~ /\.m3u8?.*$/i && recursive
          url = @base.is_a?(Addressable::URI) ? @base.join(line).to_s : File.expand_path(line, @base.to_s)
          @playlist.merge!(Avalon::M3U8Reader.read(url).playlist)
        elsif line =~ /\.m3u8?.*$/i
          url = @base.is_a?(Addressable::URI) ? @base.join(line).to_s : File.expand_path(line, @base.to_s)
          @playlist[:playlists] << url
        elsif line =~ /^[^#]/
          tags[:filename] = line
          @playlist[:files] << tags
          tags = {}
        end
      end
    end

    def duration
      files.inject(0.0) { |v, f| v + f[:duration] }
    end

    def at(offset)
      offset = offset.to_i
      raise RangeError, "Offset out of range" if offset < 0
      elapsed = 0.0
      files.each do |f|
        duration = f[:duration] * 1000
        if elapsed + duration > offset
          location = @base.is_a?(Addressable::URI) ? @base.join(f[:filename]).to_s : File.expand_path(f[:filename], @base.to_s)
          return { location: location, filename: f[:filename], offset: offset - elapsed }
        end
        elapsed += duration
      end
      raise RangeError, "Offset out of range"
    end

    def method_missing(sym, *args)
      if @playlist.key?(sym)
        @playlist[sym]
      else
        super
      end
    end
  end
end
