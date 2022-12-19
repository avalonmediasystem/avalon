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

require 'avalon/stream_mapper'

class Derivative < ActiveFedora::Base
  include DerivativeBehavior
  include DerivativeIntercom
  include FrameSize
  include MigrationTarget

  belongs_to :master_file, class_name: 'MasterFile', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDerivationOf

  property :location_url, predicate: ::RDF::Vocab::EBUCore.Locator, multiple: false do |index|
    index.as :stored_sortable
  end
  property :hls_url, predicate: Avalon::RDFVocab::Derivative.hlsURL, multiple: false do |index|
    index.as :stored_sortable
  end
  property :duration, predicate: ::RDF::Vocab::EBUCore.duration, multiple: false do |index|
    index.as :stored_sortable
  end
  property :track_id, predicate: ::RDF::Vocab::EBUCore.identifier, multiple: false
  property :hls_track_id, predicate: Avalon::RDFVocab::Derivative.hlsTrackID, multiple: false
  property :managed, predicate: Avalon::RDFVocab::Derivative.isManaged, multiple: false do |index|
    index.as ActiveFedora::Indexing::Descriptor.new(:boolean, :stored, :indexed)
  end
  property :derivativeFile, predicate: ::RDF::Vocab::EBUCore.resourceFilename, multiple: false do |index|
    index.as :stored_sortable
  end

  # Encoding datastream properties
  property :quality, predicate: ::RDF::Vocab::EBUCore.encodingLevel, multiple: false do |index|
    index.as :stored_sortable
  end
  property :mime_type, predicate: ::RDF::Vocab::EBUCore.hasMimeType, multiple: false do |index|
    index.as :stored_sortable
  end
  property :audio_bitrate, predicate: Avalon::RDFVocab::Encoding.audioBitrate, multiple: false do |index|
    index.as :displayable
  end
  property :audio_codec, predicate: Avalon::RDFVocab::Encoding.audioCodec, multiple: false do |index|
    index.as :displayable
  end
  property :video_bitrate, predicate: ::RDF::Vocab::EBUCore.bitRate, multiple: false do |index|
    index.as :displayable
  end
  property :video_codec, predicate: ::RDF::Vocab::EBUCore.hasCodec, multiple: false do |index|
    index.as :displayable
  end
  frame_size_property :resolution, predicate: Avalon::RDFVocab::Common.resolution, multiple: false do |index|
    index.as :displayable
  end

  around_destroy :delete_file!

  def initialize(*args)
    super(*args)
    self.managed = true
  end

  def set_streaming_locations!
    if managed
      path = Addressable::URI.parse(absolute_location).path
      self.location_url = Avalon::StreamMapper.stream_path(path)
      self.hls_url = Avalon::StreamMapper.map(path, 'http', format)
    end
    self
  end

  def absolute_location=(value)
    self.derivativeFile = value
    set_streaming_locations!
    derivativeFile
  end

  def to_solr
    super.tap do |solr_doc|
      solr_doc['stream_path_ssi'] = if location_url&.start_with?("rtmp")
                                      location_url.split(/:/).last
                                    else
                                      location_url
                                    end
      solr_doc['format_sim'] = self.format
    end
  end

  # TODO: move this into a service class along with master_file#update_progress_*
  def self.from_output(output, managed = true)
    derivative = Derivative.new
    derivative.managed = managed
    derivative.track_id = output[:id]
    derivative.duration = output[:duration].to_i
    # FIXME: Implement this in ActiveEncode
    # derivative.mime_type = output[:mime_type]
    derivative.quality = output[:label].sub(/quality-/, '')

    derivative.audio_bitrate = output[:audio_bitrate]
    derivative.audio_codec = output[:audio_codec]
    derivative.video_bitrate = output[:video_bitrate]
    derivative.video_codec = output[:video_codec]
    derivative.resolution = "#{output[:width]}x#{output[:height]}" if output[:width] && output[:height]

    # FIXME: Transform to stream url here? How do we distribute to the streaming server?
    derivative.location_url = output[:url]
    # For Intercom push
    derivative.hls_url = output[:hls_url] if output[:hls_url].present?

    derivative.absolute_location = output[:url]

    derivative
  end

  def bitrate
    audio_bitrate.to_i + video_bitrate.to_i
  end

  private

    def delete_file!
      loc = absolute_location
      man = managed
      yield
      DeleteDerivativeJob.perform_later(loc) if man
    end
end
