class Derivative < ActiveFedora::Base
  include ActiveFedora::Relationships

  has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream
  has_relationship "derivative_of", :is_derivation_of
  belongs_to :masterfile, :class_name=>'MasterFile', :property=>:is_derivation_of

  delegate :source, to: :descMetadata
  delegate :description, to: :descMetadata
  delegate :url, to: :descMetadata, at: [:identifier]
  
  def initialize(attrs = {})
    super(attrs)
    refresh_status
  end

  def masterfile= masterfile
    masterfile.add_relationship :has_derivation, self
    self.add_relationship :is_derivation_of, masterfile
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
  
  # Eventually this should be baked into the technical metadata instead of a one-off
  # Release Zero hack
#  def size
#    # Start with the root relative to Rails root
#    file_path = "#{Rails.root}/public/videos"
#    # Add the parent container ID with colons (:) replaced by underscores (_)
#    file_path << "/#{container.pid.gsub(":", "_")}"
#    # Now tack on the original file name
#    file_path << "/#{self.title[0]}"
#    # Finally expand it to an absolute URL
#    file_path = File.expand_path(file_path)
#    
#    logger.debug "<< Retrieving file size for #{file_path} >>"
#    File.size?(file_path)
#  end
  
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

