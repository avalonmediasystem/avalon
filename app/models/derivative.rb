class Derivative < ActiveFedora::Base
  include ActiveFedora::Associations

  belongs_to :masterfile, :class_name=>'MasterFile', :property=>:is_derivation_of

  # These fields do not fit neatly into the Dublin Core so until a long
  # term solution is found they are stored in a simple datastream in a
  # relatively flat structure.
  #
  # The only meaningful value at the moment is the url, which points to
  # the stream location. The other two are just stored until a migration
  # strategy is required.
  has_metadata name: "descMetadata", :type => ActiveFedora::SimpleDatastream do |d|
    d.field :location_url, :string
    d.field :duration, :string
    d.field :track_id, :string
  end

  delegate_to 'descMetadata', [:location_url, :duration, :track_id], unique: true

  has_metadata name: 'encoding', type: EncodingProfileDocument

  def self.create_from_master_file(masterfile, track_id)
    derivative = Derivative.create
    derivative.track_id = track_id
    
    matterhorn_response = Rubyhorn.client.instance_xml(masterfile.workflow_id)
    track_xml = matterhorn_response.ng_xml.xpath("//xmlns:workflow/ns3:mediapackage/ns3:media/ns3:track[@id=$track_id]", matterhorn_response.ng_xml.root.namespaces, {track_id: track_id})
    derivative.duration = track_xml.at("./ns3:duration").content
    derivative.location_url = track_xml.at("./ns3:url").content
    derivative.encoding.mime_type = track_xml.at("./ns3:mimetype").content
    tags = track_xml.xpath("./ns3:tags/ns3:tag").select{|t| t.content =~ /quality-(.*)/ } 
    derivative.encoding.quality = tags.first.content unless tags.empty?
    derivative.encoding.audio.audio_bitrate = track_xml.at("./ns3:audio/ns3:bitrate").content
    derivative.encoding.audio.audio_codec = track_xml.at("./ns3:audio/ns3:encoder/@type").content
    derivative.encoding.video.video_bitrate = track_xml.at("./ns3:video/ns3:bitrate").content
    derivative.encoding.video.video_codec = track_xml.at("./ns3:video/ns3:encoder/@type").content
    derivative.encoding.video.frame_rate = track_xml.at("./ns3:video/ns3:framerate").content
    width, height = track_xml.at("./ns3:video/ns3:resolution").content.split("x")
    derivative.encoding.video.resolution.video_width = width
    derivative.encoding.video.resolution.video_height = height

    derivative.masterfile = masterfile
    derivative.save
    derivative
  end

  def url_hash
    h = Digest::MD5.new
    h << location_url
    h.hexdigest
  end

  def tokenized_url(token, mobile=false)
    #uri = URI.parse(url.first)
    uri = streaming_url(mobile)
    "#{uri.to_s}?token=#{masterfile.mediapackage_id}-#{token}".html_safe
  end      

  def streaming_url(is_mobile=false)
      # We need to tweak the RTMP stream to reflect the right format for AMS.
      # That means extracting the extension from the end and placing it just
      # after the application in the URL

      # Example input: /avalon/mp4:98285a5b-603a-4a14-acc0-20e37a3514bb/b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3/MVI_0057.mp4
      regex = %r{^
        /(.+)             # application (avalon)
        /(.+:)?           # prefix      (mp4:)
        ([0-9a-f-]{36})   # media_id    (98285a5b-603a-4a14-acc0-20e37a3514bb)
        /([0-9a-f-]{36})  # stream_id   (b3d5663d-53f1-4f7d-b7be-b52fd5ca50a3)
        /(.+?)            # filename    (MVI_0057)
        (?:\.(.+))?$      # extension   (mp4)
      }x

      uri = URI.parse(location_url)
      (application, prefix, media_id, stream_id, filename, extension) = uri.path.scan(regex).flatten
      application = "avalon"
      if (is_mobile)
        application += "/audio-only" if format == 'audio'
        uri.scheme = 'http'
        uri.path = "/#{application}/#{media_id}/#{stream_id}/#{filename}.#{extension}.m3u8"
      else
        uri.path = "/#{application}/#{extension}:#{media_id}/#{stream_id}/#{filename}"
      end

      logger.info "Serving stream #{uri.to_s}"
      uri.to_s
  end

  def stream_details(token)
    {
      label: masterfile.label,
      stream_flash: tokenized_url(token, false),
      stream_hls: tokenized_url(token, true),
      poster_image: masterfile.poster_image,
      mimetype: encoding.mime_type,
      mediapackage_id: masterfile.mediapackage_id,
      format: format,
      resolution: resolution 
    }
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

  def resolution
    "#{encoding.resolution.video_width.first}x#{encoding.resolution.video_height.first}"
  end

end 
