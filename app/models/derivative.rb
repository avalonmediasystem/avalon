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

require 'avalon/stream_mapper'

class Derivative < ActiveFedora::Base
  include ActiveFedora::Associations
  include VersionableModel

  belongs_to :masterfile, :class_name=>'MasterFile', :property=>:is_derivation_of

  has_model_version 'R3'

  # These fields do not fit neatly into the Dublin Core so until a long
  # term solution is found they are stored in a simple datastream in a
  # relatively flat structure.
  #
  # The only meaningful value at the moment is the url, which points to
  # the stream location. The other two are just stored until a migration
  # strategy is required.
  has_metadata name: "descMetadata", :type => ActiveFedora::SimpleDatastream do |d|
    d.field :location_url, :string
    d.field :hls_url, :string
    d.field :duration, :string
    d.field :track_id, :string
    d.field :hls_track_id, :string
  end

  has_metadata name: 'derivativeFile', type: UrlDatastream

  has_attributes :location_url, :hls_url, :duration, :track_id, :hls_track_id, datastream: :descMetadata, multiple: false

  has_metadata name: 'encoding', type: EncodingProfileDocument

  before_destroy do
    begin
      encode = masterfile.encoder_class.find(masterfile.workflow_id)
      encode.remove_output!(track_id) if track_id.present?
      encode.remove_output!(hls_track_id) if hls_track_id.present? && track_id != hls_track_id
    rescue Exception => e
      logger.warn "Error deleting derivative: #{e.message}"
    end
  end

  def self.from_output(dists)
    #output is an array of 1 or more distributions of the same derivative (e.g. file and HLS segmented file)
    hls_output = dists.delete(dists.find {|o| o[:url].ends_with? "m3u8" })
    output = dists.first || hls_output

    derivative = Derivative.new
    derivative.track_id = output[:id]
    derivative.duration = output[:duration]
    derivative.encoding.mime_type = output[:mime_type]
    derivative.encoding.quality = output[:label].sub(/quality-/, '')

    derivative.encoding.audio.audio_bitrate = output[:audio_bitrate]
    derivative.encoding.audio.audio_codec = output[:audio_codec]
    derivative.encoding.video.video_bitrate = output[:video_bitrate]
    derivative.encoding.video.video_codec = output[:video_codec]
    derivative.encoding.video.resolution = "#{output[:width]}x#{output[:height]}" if output[:width] && output[:height]

    if hls_output
      derivative.hls_track_id = hls_output[:id]
      derivative.hls_url = hls_output[:url]
    end

    derivative.absolute_location = output[:url]
    derivative
  end

  def set_streaming_locations!
    path = URI.parse(absolute_location).path
    self.location_url = Avalon::StreamMapper.map(path,'rtmp',self.format)
    self.hls_url      = Avalon::StreamMapper.map(path,'http',self.format)
    self
  end
  
  def absolute_location
    derivativeFile.location
  end

  def absolute_location=(value)
    derivativeFile.location = value
    set_streaming_locations!
    derivativeFile.location
  end

  def tokenized_url(token, mobile=false)
    #uri = URI.parse(url.first)
    uri = streaming_url(mobile)
    "#{uri.to_s}?token=#{token}".html_safe
  end

  def streaming_url(is_mobile=false)
    is_mobile ? self.hls_url : self.location_url
  end

  def format
    case
      when (not encoding.video.empty?)
        "video"
      when (not encoding.audio.empty?)
        "audio"
      else
        "other"
      end
  end

  def to_solr(solr_doc = Hash.new)
    super(solr_doc)
    solr_doc['stream_path_ssi'] = location_url.split(/:/).last if location_url.present?
    solr_doc
  end
end 
