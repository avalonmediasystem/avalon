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
    d.field 'url', :string
    d.field 'duration', :string
    d.field 'track_id', :string
  end

  delegate_to 'descMetadata', [:url, :duration, :track_id]

  #TODO add encoding datastream and delegations
  has_metadata name: 'encoding', type: EncodingProfileDocument

  def initialize(attrs = {})
    super(attrs)
    refresh_status
  end

  def self.create_from_master_file(masterfile, track_id)
    derivative = Derivative.create
    derivative.track_id = track_id
    #TODO lookup track info from mediapackage and store
    derivative.url = streamingurl
    derivative.masterfile = masterfile
    masterfile.save
    derivative.save
    derivative
  end

  def streaming_mime_type
    matterhorn_response = Rubyhorn.client.instance_xml(masterfile.workflow_id)    
    logger.debug("<< streaming_mime_type from Matterhorn >>")
    # TODO temporary fix, xpath for streamingmimetype is not working
    # matterhorn_response.streamingmimetype.second
    matterhorn_response.mediapackage.media.track.mimetype.last
  end

  def url_hash
    h = Digest::MD5.new
    h << url.first
    h.hexdigest
  end

  def tokenized_url(token, mobile=false)
    #uri = URI.parse(url.first)
    uri = streaming_url(mobile)
    "#{uri.to_s}?token=#{mediapackage_id}-#{token}".html_safe
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

      uri = URI.parse(url.first)
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
      label: self.masterfile.label,
      stream_flash: self.tokenized_url(token, false),
      stream_hls: self.tokenized_url(token, true),
      poster_image: self.masterfile.poster_image,
      mimetype: self.masterfile.streaming_mime_type,
      mediapackage_id: self.masterfile.mediapackage_id,
      format: self.format,
      resolution: self.resolution
    }
  end

  def format
    case masterfile.media_type
      when 'Moving image'
        "video"
      when "Sound"
        "audio"
      else
        "other"
      end
  end

  def resolution
    w = Rubyhorn.client.instance_xml masterfile.workflow_id
    w.streamingresolution.first
  end

end 
