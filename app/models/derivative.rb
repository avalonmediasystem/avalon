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

  def masterfile= parent
    super parent
    self.masterfile.derivatives << self
#    masterfile.add_relationship :has_derivation, self
#    self.add_relationship :is_derivation_of, masterfile
  end

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

  def tokenized_url(token)
    uri = URI.parse(url.first)
    "#{uri.to_s}?token=#{token}&pid=#{pid}&hash=#{url_hash}"
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

