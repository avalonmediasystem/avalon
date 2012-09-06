class MasterFile < FileAsset
  include ActiveFedora::Relationships

  has_relationship "part_of", :is_part_of
  has_relationship "derivatives", :has_derivation
  has_metadata name: 'descMetadata', type: DublinCoreDocument
  belongs_to :mediaobject, :class_name=>'MediaObject', :property=>:is_part_of
  
  delegate :source, to: :descMetadata
  delegate :description, to: :descMetadata
  delegate :url, to: :descMetadata, at: [:identifier]
  delegate :size, to: :descMetadata, at: [:extent]
  delegate :media_type, to: :descMetadata, at: [:dc_type]
  delegate :media_format, to: :descMetadata, at: [:medium]

    # First and simplest test - make sure that the uploaded file does not exceed the
    # limits of the system. For now this is hard coded but should probably eventually
    # be set up in a configuration file somewhere
    #
    # 250 MB is the file limit for now
    MAXIMUM_UPLOAD_SIZE = (2**20) * 250

  def container= obj
    super obj
    self.container.add_relationship(:has_part, self)
  end

  def mediapackage_id
    matterhorn_response = Rubyhorn.client.instance_xml(source.first)
    matterhorn_response.workflow.mediapackage.id.first
  end

  # A hacky way to handle the description for now. This should probably be refactored
  # to stop pulling if the status is stopped or completed
  def status
    unless source.nil? or source.empty?
      refresh_status
    else
      descMetadata.description = "Status is currently unavailable"
    end
    descMetadata.description.first
  end

  def percent_complete
    matterhorn_response = Rubyhorn.client.instance_xml(source[0])
    totalOperations = matterhorn_response.workflow.operations.operation.length
    finishedOperations = 0
    matterhorn_response.workflow.operations.operation.operationState.each {|state| finishedOperations = finishedOperations + 1 if state == "FINISHED" || state == "SKIPPED"}
    (finishedOperations / totalOperations) * 100
  end

  def exceeds_upload_limit?(size)
    size > MAXIMUM_UPLOAD_SIZE
  end
  
  protected
  def refresh_status
    matterhorn_response = Rubyhorn.client.instance_xml(source[0])
    status = matterhorn_response.workflow.state[0]
 
    descMetadata.description = case status
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
