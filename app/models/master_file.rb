class MasterFile < FileAsset
  include ActiveFedora::Relationships

  has_relationship "part_of", :is_part_of
  has_relationship "derivatives", :has_derivation
  has_metadata name: 'descMetadata', type: DublinCoreDocument
  has_metadata name: 'statusMetadata', :type => ActiveFedora::SimpleDatastream do |d|
    d.field :percent_complete, :string
    d.field :status_code, :string
  end

  belongs_to :mediaobject, :class_name=>'MediaObject', :property=>:is_part_of
  
  delegate :workflow_id, to: :descMetadata, at: [:source], unique: true
  #delegate :description, to: :descMetadata
  delegate :url, to: :descMetadata, at: [:identifier], unique: true
  delegate :size, to: :descMetadata, at: [:extent], unique: true
  delegate :media_type, to: :descMetadata, at: [:dc_type], unique: true
#  delegate :media_format, to: :descMetadata, at: [:medium], unique: true

  delegate_to 'statusMetadata', [:percent_complete, :status_code]

    # First and simplest test - make sure that the uploaded file does not exceed the
    # limits of the system. For now this is hard coded but should probably eventually
    # be set up in a configuration file somewhere
    #
    # 250 MB is the file limit for now
    MAXIMUM_UPLOAD_SIZE = (2**20) * 250

  AUDIO_TYPES = ["audio/vnd.wave", "audio/mpeg", "audio/mp3", "audio/mp4", "audio/wav",
      "audio/x-wav"]
  VIDEO_TYPES = ["application/mp4", "video/mpeg", "video/mpeg2", "video/mp4", "video/quicktime", "video/avi"]
  UNKNOWN_TYPES = ["application/octet-stream", "application/x-upload-data"]

  def container= obj
    super obj
    self.container.add_relationship(:has_part, self)
  end

  def save
    super
    unless self.container.nil?
      self.container.save(validate: false)
    end
  end  

  def destroy
    parent = self.container
    parent.parts_remove self

    unless self.new_object?
      parent.save(validate: false)

      Rubyhorn.client.stop(self.workflow_id)

      self.delete
    end
  end

  def setContent(file, content_type = nil)
    if file.is_a? ActionDispatch::Http::UploadedFile
      self.media_type = determine_format(file.original_filename, file.content_type)
      saveOriginal(file, file.original_filename)
    else
      self.media_type = determine_format(File.basename(file), content_type)
      saveOriginal(file, nil)
    end
  end

  def process
    sendToMatterhorn
    self.save
  end

  def mediapackage_id
    matterhorn_response = Rubyhorn.client.instance_xml(workflow_id)
    matterhorn_response.workflow.mediapackage.id.first
  end

  # A hacky way to handle the description for now. This should probably be refactored
  # to stop pulling if the status is stopped or completed
  #def status_description
    #unless source.nil? or source.empty?
      #refresh_status
    #else
      #descMetadata.description = "Status is currently unavailable"
    #end
    #descMetadata.description.first
  #end

  #def exceeds_upload_limit?(size)
    #size > MAXIMUM_UPLOAD_SIZE
  #end

  def status_description
    case self.status_code.first 
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
  end  

  def updateProgress
    matterhorn_response = Rubyhorn.client.instance_xml(workflow_id)

    @masterfile.percent_complete = percent_complete(matterhorn_response)
    @masterfile.status_code = matterhorn_response.workflow.state[0]
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

  def percent_complete matterhorn_response
    totalOperations = matterhorn_response.workflow.operations.operation.length
    finishedOperations = 0
    matterhorn_response.workflow.operations.operation.operationState.each {|state| finishedOperations += 1 if state == "SUCCEEDED" || state == "SKIPPED"}
    percent = finishedOperations * 100 / totalOperations
    puts "percent_complete #{percent}"
    percent.to_s
  end

  def determine_format(filename, content_type = nil)
    upload_format = 'Unknown'
    upload_format = 'Moving image' if MasterFile::VIDEO_TYPES.include?(content_type)
    upload_format = 'Sound' if MasterFile::AUDIO_TYPES.include?(content_type)

    # If the content type cannot be inferred from the MIME type fall back on the
    # list of unknown types. This is different than a generic fallback because it
    # is skipped for known invalid extensions like application/pdf
    upload_format = determine_format_by_extension(file) if MasterFile::UNKNOWN_TYPES.include?(content_type)
    logger.info "<< Uploaded file appears to be #{@upload_format} >>"
    return upload_format
  end

  def determine_format_by_extension(filename)
    audio_extensions = ["mp3", "wav", "aac", "flac"]
    video_extensions = ["mpeg4", "mp4", "avi", "mov"]

    logger.debug "<< Using fallback method to guess the format >>"

    extension = filename.split(".").last.downcase
    logger.debug "<< File extension is #{extension} >>"

    # Default to unknown
    format = 'Unknown'
    format = 'Moving image' if video_extensions.include?(extension)
    format = 'Sound' if audio_extensions.include?(extension)

    return format
  end

  def sendToMatterhorn
    file = File.new self.url
    args = {"title" => self.pid , "flavor" => "presenter/source", "filename" => File.basename(file)}
    if self.media_type == 'Sound'
      args['workflow'] = "fullaudio"
    elsif self.media_type == 'Moving image'
      args['workflow'] = "hydrant"
    end
    logger.debug "<< Calling Matterhorn with arguments: #{args} >>"
    workflow_doc = Rubyhorn.client.addMediaPackage(file, args)
    #master_file.description = "File is being processed"

    # I don't know why this has to be double escaped with two arrays
    self.workflow_id = workflow_doc.workflow.id[0]
  end

  def saveOriginal(file, original_name)
    realpath = File.realpath(file.path)
    if !original_name.nil?
      newpath = File.dirname(realpath) + "/" + original_name
      File.rename(realpath, newpath)
      self.url = newpath
    else 
      self.url = realpath
    end
    self.size = file.size.to_s

    logger.debug "<< File location #{ self.url } >>"
    logger.debug "<< Filesize #{ self.size } >>"

    #FIXME next line
    #apply_depositor_metadata(master_file)
  end

end
