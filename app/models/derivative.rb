class Derivative < ActiveFedora::Base
  include ActiveFedora::Associations

  has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream
#  has_relationship "derivative_of", :is_derivation_of
  belongs_to :masterfile, :class_name=>'MasterFile', :property=>:is_derivation_of

  delegate :source, to: :descMetadata
  delegate :description, to: :descMetadata
  delegate :url, to: :descMetadata, at: [:identifier]
  
  def initialize(attrs = {})
    super(attrs)
    refresh_status
  end

#  def masterfile= parent
#    self.masterfile = parent
#    self.masterfile.derivatives << self
#    masterfile.add_relationship :has_derivation, self
#    self.add_relationship :is_derivation_of, masterfile
#  end

  # A hacky way to handle the description for now. This should probably be refactored
  # to stop pulling if the status is stopped or completed
  def status
    unless source.nil? or source.empty?
      refresh_status
    else
      self.description = "Status is currently unavailable"
    end
    self.description.first
  end

  def status_complete
    matterhorn_response = Rubyhorn.client.instance_xml(source[0])
    totalOperations = matterhorn_response.workflow.operations.operation.length
    finishedOperations = 0
    matterhorn_response.workflow.operations.operation.operationState.each {|state| finishedOperations = finishedOperations + 1 if state == "FINISHED" || state == "SKIPPED"}
    (finishedOperations / totalOperations) * 100
  end
  
  def thumbnail
    w = Rubyhorn.client.instance_xml source[0]
    w.searchpreview.first
  end   
  
  def mediapackage_id
    matterhorn_response = Rubyhorn.client.instance_xml(source[0])
    matterhorn_response.workflow.mediapackage.id.first
  end

  def streaming_mime_type
    matterhorn_response = Rubyhorn.client.instance_xml(source[0])    
    logger.debug("<< streaming_mime_type from Matterhorn >>")
    # TODO temporary fix, xpath for streamingmimetype is not working
    # matterhorn_response.workflow.streamingmimetype.second
    matterhorn_response.workflow.mediapackage.media.track.mimetype.last
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

      logger.debug "currentStream value - #{uri.to_s}"
      uri.to_s
  end

  def stream_details(token)
    {
      label: self.masterfile.label,
      stream_flash: self.tokenized_url(token, false),
      stream_hls: self.tokenized_url(token, true),
      mimetype: self.streaming_mime_type,
      mediapackage_id: self.masterfile.mediapackage_id,
      format: self.format
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
  
  protected
  def refresh_status
    matterhorn_response = Rubyhorn.client.instance_xml(source[0])
    status = matterhorn_response.workflow.state[0]
 
    self.description = case status
      when "INSTANTIATED"
        "Preparing file for conversion"
      when "RUNNING"
        "Creating derivatives"
      when "SUCCEEDED"
        "Processing is complete"
      when "FAILED"
        "File(s) could not be processed"
      when "STOPPED"
        "Processing has been stopped"
      else
        "No file(s) uploaded"
      end
    save
  end
end

