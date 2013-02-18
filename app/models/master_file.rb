require 'hydrant/matterhorn_jobs'
require 'fileutils'

class MasterFile < ActiveFedora::Base
  include ActiveFedora::Associations
  include Hydra::ModelMethods
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata

  belongs_to :mediaobject, :class_name=>'MediaObject', :property=>:is_part_of
  has_many :derivatives, :class_name=>'Derivative', :property=>:is_derivation_of

  has_metadata name: 'descMetadata', :type => ActiveFedora::SimpleDatastream do |d|
    d.field :file_location, :string
    d.field :file_checksum, :string
    d.field :file_size, :string
    d.field :duration, :string
    d.field :file_format, :string
  end

  has_metadata name: 'mhMetadata', :type => ActiveFedora::SimpleDatastream do |d|
    d.field :workflow_id, :string
    d.field :mediapackage_id, :string
    d.field :percent_complete, :string
    d.field :status_code, :string
    d.field :failures, :string
  end

  delegate_to 'descMetadata', [:file_location, :file_checksum, :file_size, :duration, :file_format], unique: true
  delegate_to 'mhMetadata', [:workflow_id, :mediapackage_id, :percent_complete, :status_code, :failures], unique:true

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

  QUALITY_ORDER = { "low" => 1, "medium" => 2, "high" => 3 }

  END_STATES = ['STOPPED', 'SUCCEEDED', 'FAILED', 'SKIPPED']

  def save_parent
    unless mediaobject.nil?
      mediaobject.save(validate: false)  
    end
  end

  def destroy
    parent = mediaobject
    parent.parts -= [self]

    unless new_object?
      parent.save(validate: false)
      Rubyhorn.client.stop(workflow_id) if workflow_id
      delete
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
    args = {"url" => URI.join("file:///", URI.escape(file_location)).to_s,
                "title" => pid,
                "flavor" => "presenter/source",
                "filename" => File.basename(file_location)}

    if file_format == 'Sound'
      args['workflow'] = "fullaudio"
    elsif file_format == 'Moving image'
      args['workflow'] = "hydrant"
    end
    
    m = MatterhornJobs.new
    m.send_request args
  end

  def status_description
    case status_code
      when "INSTANTIATED"
        "Preparing file for conversion"
      when "RUNNING"
        "Creating derivatives"
      when "SUCCEEDED"
        s = self.failures.to_i > 0 ? " (#{failures} failed steps)" : ""
        "Processing is complete#{s}"
      when "FAILED"
        "File(s) could not be processed"
      when "STOPPED"
        "Processing has been stopped"
      else
        "Waiting for conversion to begin"
      end
  end

  def stream_details(token)
    flash, hls = [], []
    derivatives.each do |d|
      common = { quality: d.encoding.quality.first,
                 mimetype: d.encoding.mime_type.first,
                 format: d.format } 
      flash << common.merge(url: d.tokenized_url(token, false))
      hls << common.merge(url: d.tokenized_url(token, true)) 
    end

    # Sorts the streams in order of quality, note: Hash order only works in Ruby 1.9 or later
    flash = sort_streams flash
    hls = sort_streams hls

    poster_path = Rails.application.routes.url_helpers.poster_master_file_path(self) unless poster.new?

    # Returns the hash
    {
      label: label,
      poster_image: poster_path,
      mediapackage_id: mediapackage_id,
      stream_flash: flash, 
      stream_hls: hls 
    }
  end

  def sort_streams array
    array.sort { |x, y| QUALITY_ORDER[x[:quality]] <=> QUALITY_ORDER[y[:quality]] }
  end

  def finished_processing?
    END_STATES.include?(status_code)
  end

  def poster_url
    #poster.url yeilds something like "objects/changeme%3A314/datastreams/poster/content" which needs fedora's base added on to it
    poster.new? ? nil : ActiveFedora.fedora.config[:url] + "/" + poster.url
  end

  def thumbnail_url
    #thumbnail.url yeilds something like "objects/changeme%3A314/datastreams/thumbnail/content" which needs fedora's base added on to it
    thumbnail.new? ? nil : ActiveFedora.fedora.config[:url] + "/" + thumbnail.url
  end

  def update_progress!( params, matterhorn_response )

    response_duration = matterhorn_response.source_tracks(0).duration.try(:first)

    self.percent_complete = calculate_percent_complete(matterhorn_response)
    self.status_code = matterhorn_response.state[0]
    self.failures = matterhorn_response.operations.operation.operation_state.select { |state| state == 'FAILED' }.length.to_s

    # Because there is no attribute_changed? in AF
    # we want to find out if the duration has changed
    # so we can update it along with the media object.
    if response_duration && response_duration !=  self.duration
      self.duration = response_duration
      save
      
      # The media object has a duration that is the sum of all master files.
      media_object = self.mediaobject
      media_object.populate_duration!
      media_object.save( validate: false )
    end

    save
  end

  def update_progress_on_success!( matterhorn_response )
    # First step is to create derivative objects within Fedora for each
    # derived item. For this we need to pick only those which 
    # have a 'streaming' tag attached
    
    # Why do it this way? It will create a dynamic node that can be
    # passed to the helper without any extra work
    matterhorn_response.streaming_tracks.size.times do |i|
      Derivative.create_from_master_file( self, matterhorn_response.streaming_tracks(i) )
    end

    # Some elements of the original file need to be stored as well even 
    # though they are not being used right now. This includes a checksum 
    # which can be used to validate the file has not changed and the 
    # thumbnail.
    #
    # The thumbnail is tricky because Fedora cannot ingest from a URI. That 
    # means if one exists we should copy it over to a temporary location and
    # then hand the bits off to Fedora
    self.mediapackage_id = matterhorn_response.mediapackage.id.first
    
    unless matterhorn_response.source_tracks(0).nil?
      self.file_checksum = matterhorn_response.source_tracks(0).checksum
    end

    thumbnail = matterhorn_response.thumbnail_images(0)      

    # TODO : Since these are the same write a method to DRY up updating an
    #        image datastream
    unless thumbnail.empty?
      thumbnailURI = URI.parse(thumbnail.url.first)
      # Rubyhorn fails if you don't provide a leading / in the provided path
      self.thumbnail.content = Rubyhorn.client.get(thumbnailURI.path[1..-1]) 
      self.thumbnail.mimeType = thumbnail.mimetype.first
    end
    
    # The poster element needs the same treatment as the thumbnail except 
    # for being located at player+preview and not search+preview
    poster = matterhorn_response.poster_images(0)

    unless poster.empty?
      poster_uri = URI.parse(poster.url.first)
      self.poster.content = Rubyhorn.client.get(poster_uri.path[1..-1])
      self.poster.mimeType = poster.mimetype.first
    end

    save

  end

  protected

  def calculate_percent_complete matterhorn_response
    totalOperations = matterhorn_response.operations.operation.length

    # DEBUG
    logger.debug "<< Inspecting nodes for percentage >>"
    logger.debug matterhorn_response.operations
    # END DEBUG
    finishedOperations = matterhorn_response.operations.operation.operation_state.select { |state| END_STATES.include? state }.length
    percent = finishedOperations * 100 / totalOperations
    logger.debug "percent_complete #{percent}"
    percent.to_s
  end

  def determine_format(file, content_type = nil)
    #FIXME Catch exceptions here and do something helpful like log warning and set format to unknown
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
      config_path = Hydrant::Configuration['matterhorn']['media_path']
      newpath = nil
      if !config_path.nil? and File.directory?(config_path)
        newpath = File.join(Hydrant::Configuration['matterhorn']['media_path'], original_name)
        FileUtils.cp(realpath, newpath)
      else
        newpath = File.join(File.dirname(realpath), original_name)
        File.rename(realpath, newpath)
      end
      self.file_location = newpath
    else 
      self.file_location = realpath
    end

    self.file_size = file.size.to_s

    logger.debug "<< File location #{ file_location } >>"
    logger.debug "<< Filesize #{ file_size } >>"
  end


end
