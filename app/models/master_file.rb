require 'hydrant/matterhorn_jobs'

class MasterFile < ActiveFedora::Base
  include ActiveFedora::Associations
  include Hydra::ModelMethods
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata

  belongs_to :mediaobject, :class_name=>'MediaObject', :property=>:is_part_of
  has_many :derivatives, :class_name=>'Derivative', :property=>:is_derivation_of

  has_metadata name: 'descMetadata', :type => ActiveFedora::SimpleDatastream do |d|
    d.field :url, :string
    d.field :checksum, :string
    d.field :size, :string
    d.field :duration, :string
    d.field :file_format, :string
  end

  has_metadata name: 'mhMetadata', :type => ActiveFedora::SimpleDatastream do |d|
    d.field :workflow_id, :string
    d.field :mediapackage_id, :string
    d.field :percent_complete, :string
    d.field :status_code, :string
  end

  delegate_to 'descMetadata', [:url, :checksum, :size, :duration, :media_type]
  delegate_to 'mhMetadata', [:workflow_id, :mediapackage_id, :percent_complete, :status_code]

  has_file_datastream name: 'thumbnail'
  has_file_datastream name: 'poster'

  # First and simplest test - make sure that the uploaded file does not exceed the
  # limits of the system. For now this is hard coded but should probably eventually
  # be set up in a configuration file somewhere
  #
  # 250 MB is the file limit for now
  MAXIMUM_UPLOAD_SIZE = (2**20) * 250

  AUDIO_TYPES = ["audio/vnd.wave", "audio/mpeg", "audio/mp3", "audio/mp4", "audio/wav", "audio/x-wav"]
  VIDEO_TYPES = ["application/mp4", "video/mpeg", "video/mpeg2", "video/mp4", "video/quicktime", "video/avi"]
  UNKNOWN_TYPES = ["application/octet-stream", "application/x-upload-data"]

#  def mediaobject= parent
#    super parent
#    self.mediaobject.parts << self
#    self.mediaobject.add_relationship(:has_part, self)
#  end

  def save_parent
    unless self.mediaobject.nil?
      self.mediaobject.save(validate: false)  
    end
  end

#  def save
#    super
#    unless self.mediaobject.nil?
#      self.mediaobject.save(validate: false)
#    end
#  end  

  def destroy
    parent = self.mediaobject
    parent.parts -= [self]

    unless self.new_object?
      parent.save(validate: false)
      Rubyhorn.client.stop(self.workflow_id) if self.workflow_id
      self.delete
    end
  end

  def setContent(file, content_type = nil)
    if file.is_a? ActionDispatch::Http::UploadedFile
      self.file_format = determine_format(file.tempfile, file.content_type)
      saveOriginal(file, file.original_filename)
    else
      self.file_format = determine_format(file, content_type)
      saveOriginal(file, nil)
    end
  end

  def process
    args = {"url" => "file://" + self.url,
                "title" => self.pid,
                "flavor" => "presenter/source",
                "filename" => File.basename(self.url)}

    if self.file_format == 'Sound'
      args['workflow'] = "fullaudio"
    elsif self.file_format == 'Moving image'
      args['workflow'] = "hydrant"
    end
    
    m = MatterhornJobs.new
    m.send_request args
  end

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
        "Waiting for conversion to begin"
      end
  end  

  def updateProgress workflow_id
    raise "Workflow id does not match existing MasterFile workflow_id" unless self.workflow_id == workflow_id
    matterhorn_response = Rubyhorn.client.instance_xml(workflow_id)

    #TODO set duration, mediapackage_id, checksum, etc if not already set

    self.percent_complete = calculate_percent_complete(matterhorn_response)
    self.status_code = matterhorn_response.state[0]
    self.save
  end

  def finished_processing?
    status_code = self.status_code.first
    ['STOPPED', 'SUCCEEDED', 'FAILED'].include?(status_code)
  end

  protected

  def calculate_percent_complete matterhorn_response
    totalOperations = matterhorn_response.operations.operation.length
    finishedOperations = 0
    matterhorn_response.operations.operation.operationState.each {|state| finishedOperations += 1 if state == "SUCCEEDED" || state == "SKIPPED"}
    percent = finishedOperations * 100 / totalOperations
    puts "percent_complete #{percent}"
    percent.to_s
  end

  def determine_format(file, content_type = nil)
    media_format = Mediainfo.new file

    # It appears that formats like MP4 can be caught as both audio and video
    # so a case statement should flow in the preferred order
    upload_format = case
                    when media_format.video?
                      'Moving image'
                    when media_format.audio?
                       'Sound'
                    else
                       'Unknown'
                    end 
  
    return upload_format
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
  end

end
