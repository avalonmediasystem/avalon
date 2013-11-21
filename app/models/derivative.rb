# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

require 'avalon/file_resolver'

class Derivative < ActiveFedora::Base
  include ActiveFedora::Associations
  include Hydra::ModelMixins::Migratable

  class_attribute :url_handler

  belongs_to :masterfile, :class_name=>'MasterFile', :property=>:is_derivation_of

  before_save { |obj| obj.current_migration = 'R2' }

  # These fields do not fit neatly into the Dublin Core so until a long
  # term solution is found they are stored in a simple datastream in a
  # relatively flat structure.
  #
  # The only meaningful value at the moment is the url, which points to
  # the stream location. The other two are just stored until a migration
  # strategy is required.
  has_metadata name: "descMetadata", :type => ActiveFedora::SimpleDatastream do |d|
    d.field :absolute_location, :string
    d.field :location_url, :string
    d.field :hls_url, :string
    d.field :duration, :string
    d.field :track_id, :string
    d.field :hls_track_id, :string
  end

  delegate_to 'descMetadata', [:location_url, :hls_url, :duration, :track_id, :hls_track_id], unique: true

  has_metadata name: 'encoding', type: EncodingProfileDocument

  def self.url_handler
    url_handler_class = Avalon::Configuration['streaming']['server'].to_s.classify
    @url_handler ||= UrlHandler.const_get(url_handler_class.to_sym)
  end

  # Getting the track ID from the fragment is not great but it does reduce the number
  # of calls to Matterhorn 
  def self.create_from_master_file(masterfile, markup)
    
    # Looks for an existing derivative of the same quality
    # and adds the track URL to it
    quality = markup.tags.quality.first.split('-')[1] unless markup.tags.quality.empty?
    derivative = nil
    masterfile = MasterFile.find(masterfile.pid)
    masterfile.derivatives.each do |d|
      derivative = d if d.encoding.quality.first == quality
    end 

    # If same quality derivative doesn't exist, create one
    if derivative.blank?
      derivative = Derivative.create 
      
      derivative.duration = markup.duration.first
      derivative.encoding.mime_type = markup.mimetype.first
      derivative.encoding.quality = quality 

      derivative.encoding.audio.audio_bitrate = markup.audio.a_bitrate.first
      derivative.encoding.audio.audio_codec = markup.audio.a_codec.first
 
      unless markup.video.empty?
        derivative.encoding.video.video_bitrate = markup.video.v_bitrate.first
        derivative.encoding.video.video_codec = markup.video.v_codec.first
        derivative.encoding.video.resolution = markup.video.resolution.first
      end
    end

    if markup.tags.tag.include? "hls"   
      derivative.hls_track_id = markup.track_id
      derivative.hls_url = markup.url.first
    else
      derivative.track_id = markup.track_id
      derivative.location_url = markup.url.first
      derivative.absolute_location
    end

    derivative.masterfile = masterfile
    derivative.save
    
    derivative
  end

  def tokenized_url(token, mobile=false)
    #uri = URI.parse(url.first)
    uri = streaming_url(mobile)
    "#{uri.to_s}?token=#{masterfile.mediapackage_id}-#{token}".html_safe
  end      

  def absolute_location
    if descMetadata.absolute_location.blank?
      (application, prefix, media_id, stream_id, filename, extension) = parse_location
      path = "STREAM_BASE/#{media_id}/#{stream_id}/#{filename}.#{prefix||extension}"
      resolver = Avalon::FileResolver.new
      resolver.overrides['STREAM_BASE'] ||= "file://" + File.join(Rails.root,'red5/webapps/avalon/streams')
      descMetadata.absolute_location = resolver.path_to(path) rescue nil
    end
    descMetadata.absolute_location.first
  end

  def absolute_location=(value)
    descMetadata.absolute_location = value
  end

  def streaming_url(is_mobile=false)
    # We need to tweak the RTMP stream to reflect the right format for AMS.
    # That means extracting the extension from the end and placing it just
    # after the application in the URL

    protocol = is_mobile ? 'http' : 'rtmp'

    (application, prefix, media_id, stream_id, filename, extension) = parse_location
    if extension.nil? or prefix.nil?
      prefix = extension = [extension,prefix].find { |thing| not thing.nil? }
    end

    template = ERB.new(self.class.url_handler.patterns[protocol][format])
    result = File.join(Avalon::Configuration['streaming']["#{protocol}_base"],template.result(binding))
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

  def delete
    job_urls = []
    job_urls << Rubyhorn.client.delete_track(masterfile.workflow_id, track_id) 
    job_urls << Rubyhorn.client.delete_hls_track(masterfile.workflow_id, hls_track_id) if hls_track_id.present? 

    # Logs retraction jobs for sysadmin 
    File.open(Avalon::Configuration['matterhorn']['cleanup_log'], "a+") { |f| f << job_urls.join("\n") + "\n" }

    super
  end

  def parse_location
    # Example input: /avalon/mp4:98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4
    regex = %r{^
      /(.+)             # application (avalon)
      /(?:(.+):)?       # prefix      (mp4:)
      ([^\/]+)          # media_id    (98285a5b-603a-4a14-acc0-20e37a3514bb)
      /([^\/]+)         # stream_id   (b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3)
      /(.+?)            # filename    (MVI_0057)
      (?:\.(.+))?$      # extension   (mp4)
    }x

    uri = URI.parse(location_url)
    uri.path.scan(regex).flatten
  end
end 
