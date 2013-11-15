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

require 'fileutils'

class MasterFile < ActiveFedora::Base
  include ActiveFedora::Associations
  include Hydra::ModelMethods
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include Hydra::ModelMixins::Migratable

  belongs_to :mediaobject, :class_name=>'MediaObject', :property=>:is_part_of
  has_many :derivatives, :class_name=>'Derivative', :property=>:is_derivation_of

  has_metadata name: 'descMetadata', :type => ActiveFedora::SimpleDatastream do |d|
    d.field :file_location, :string
    d.field :file_checksum, :string
    d.field :file_size, :string
    d.field :duration, :string
    d.field :file_format, :string
    d.field :poster_offset, :string
    d.field :thumbnail_offset, :string
  end

  has_metadata name: 'mhMetadata', :type => ActiveFedora::SimpleDatastream do |d|
    d.field :workflow_id, :string
    d.field :workflow_name, :string
    d.field :mediapackage_id, :string
    d.field :percent_complete, :string
    d.field :percent_succeeded, :string
    d.field :percent_failed, :string
    d.field :status_code, :string
    d.field :operation, :string
    d.field :error, :string
    d.field :failures, :string
  end

  delegate_to 'descMetadata', [:file_location, :file_checksum, :file_size, :duration, :file_format, :poster_offset, :thumbnail_offset], unique: true
  delegate_to 'mhMetadata', [:workflow_id, :workflow_name, :mediapackage_id, :percent_complete, :percent_succeeded, :percent_failed, :status_code, :operation, :error, :failures], unique:true

  has_file_datastream name: 'thumbnail'
  has_file_datastream name: 'poster'

  validates_each :poster_offset, :thumbnail_offset do |record, attr, value|
    unless value.nil? or value.to_i.between?(0,record.duration.to_i)
      record.errors.add attr, "must be between 0 and #{record.duration}"
    end
  end

  before_save { |obj| obj.current_migration = 'R2' }
  before_save 'update_stills_from_offset!'

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
  WORKFLOWS = ['fullaudio', 'avalon', 'avalon-skip-transcoding']
  
  def save_parent
    unless mediaobject.nil?
      mediaobject.save(validate: false)  
    end
  end

  def destroy
    delete
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

  def set_workflow( custom_workflow = nil )
    if custom_workflow && custom_workflow.in?(WORKFLOWS)
      workflow = custom_workflow
    elsif self.file_format == 'Sound'
      workflow = 'fullaudio'
    elsif self.file_format == 'Moving image'
      workflow = 'avalon'
    else
      logger.warn "Could not find workflow for: #{self}"
    end
    self.workflow_name = workflow
  end

  alias_method :'_mediaobject=', :'mediaobject='

  # This requires the MasterFile having an actual pid
  def mediaobject=(mo)
    # Removes existing association
    if self.mediaobject.present?
      self.mediaobject.parts_with_order_remove self
      self.mediaobject.parts -= [self]
    end

    self._mediaobject=(mo)
    unless self.mediaobject.nil?
      self.mediaobject.parts_with_order += [self]
      self.mediaobject.parts += [self]
    end
  end

  def delete 
    # Stops all processing and deletes the workflow
    unless workflow_id.blank? || new_object? || finished_processing?
      Rubyhorn.client.stop(workflow_id)
    end

    mo = self.mediaobject
    self.mediaobject = nil

    derivatives_deleted = true
    self.derivatives.each do |d|
      if !d.delete
        derivatives_deleted = false
      end
    end
    if !derivatives_deleted 
      #flash[:error] << "Some derivatives could not be deleted."
    end 
    clear_association_cache
    
    super

    #Only save the media object if the master file was successfully deleted
    mo.save(validate: false)
  end

  def process
    args = {    "url" => "file://" + URI.escape(file_location),
                "title" => pid,
                "flavor" => "presenter/source",
                "filename" => File.basename(file_location),
                'workflow' => self.workflow_name,
            }

    m = MatterhornJobs.new
    m.send_request args
  end

  def status?(value)
    status_code == value
  end

  def failed?
    status?('FAILED')
  end

  def succeeded?
    status?('SUCCEEDED')
  end

  def stream_details(token,host=nil)
    flash, hls = [], []
    derivatives.each do |d|
      common = { quality: d.encoding.quality.first,
                 mimetype: d.encoding.mime_type.first,
                 format: d.format } 
      flash << common.merge(url: Avalon.rehost(d.tokenized_url(token, false),host))
      hls << common.merge(url: Avalon.rehost(d.tokenized_url(token, true),host)) 
    end

    # Sorts the streams in order of quality, note: Hash order only works in Ruby 1.9 or later
    flash = sort_streams flash
    hls = sort_streams hls

    poster_path = Rails.application.routes.url_helpers.poster_master_file_path(self) unless poster.new?

    # Returns the hash
    {
      label: label,
      is_video: is_video?,
      poster_image: poster_path,
      mediapackage_id: mediapackage_id,
      stream_flash: flash, 
      stream_hls: hls 
    }
  end

  def is_video?
    self.file_format != "Sound"
  end

  def sort_streams array
    array.sort { |x, y| QUALITY_ORDER[x[:quality]] <=> QUALITY_ORDER[y[:quality]] }
  end

  def finished_processing?
    END_STATES.include?(status_code)
  end

  def update_progress!( params, matterhorn_response )

    response_duration = matterhorn_response.source_tracks(0).duration.try(:first)

    pct = calculate_percent_complete(matterhorn_response)
    self.percent_complete  = pct[:complete].to_i.to_s
    self.percent_succeeded = pct[:succeeded].to_i.to_s
    self.percent_failed    = (pct[:failed].to_i + pct[:stopped].to_i).to_s

    self.status_code = matterhorn_response.state[0]
    self.failures = matterhorn_response.operations.operation.operation_state.select { |state| state == 'FAILED' }.length.to_s
    self.operation = matterhorn_response.find_by_terms(:operations,:operation).select { |n| ['RUNNING','FAILED','SUCCEEDED'].include?n['state'] }.last.try(:[],'description')
    self.error = matterhorn_response.errors.last

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
      Derivative.create_from_master_file(self, matterhorn_response.streaming_tracks(i))
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
    if thumbnail.present? and self.thumbnail.content.blank?
      thumbnailURI = URI.parse(thumbnail.url.first)
      # Rubyhorn fails if you don't provide a leading / in the provided path
      self.thumbnail.content = Rubyhorn.client.get(thumbnailURI.path[1..-1]) 
      self.thumbnail.mimeType = thumbnail.mimetype.first
    end
    
    # The poster element needs the same treatment as the thumbnail except 
    # for being located at player+preview and not search+preview
    poster = matterhorn_response.poster_images(0)

    if poster.present? and self.poster.content.blank?
      poster_uri = URI.parse(poster.url.first)
      self.poster.content = Rubyhorn.client.get(poster_uri.path[1..-1])
      self.poster.mimeType = poster.mimetype.first
    end

    save

  end

  alias_method :'_poster_offset=', :'poster_offset='
  def poster_offset=(value)
    set_image_offset(:poster,value)
    set_image_offset(:thumbnail,value) # Keep stills in sync
  end

  alias_method :'_thumbnail_offset=', :'thumbnail_offset='
  def thumbnail_offset=(value)
    set_image_offset(:thumbnail,value)
    set_image_offset(:poster,value)  # Keep stills in sync
  end

  def set_image_offset(type, value)
    milliseconds = if value.is_a?(Numeric)
      value.floor
    elsif value.is_a?(String)
      result = 0
      segments = value.split(/:/).reverse
      segments.each_with_index { |v,i| result += i > 0 ? v.to_f * (60**i) * 1000 : (v.to_f * 1000) }
      result.to_i
    else
      value.to_i
    end
    
    return milliseconds if milliseconds == self.send("#{type}_offset").to_i

    @stills_to_update ||= []
    @stills_to_update << type
    self.send("_#{type}_offset=".to_sym,milliseconds.to_s)
    milliseconds
  end

  def update_stills_from_offset!
    if @stills_to_update.present?
      # Update stills together
      self.class.extract_still(self.pid, :type => 'both', :offset => self.poster_offset)

      # Update stills independently
      # @stills_to_update.each do |type|
      #   self.class.extract_still(self.pid, :type => type, :offset => self.send("#{type}_offset"))
      # end
      @stills_to_update = []
    end
    true
  end

  def extract_still(options={})
    default_frame_sizes = {
      'poster'    => '1024x768',
      'thumbnail' => '160x120'
    }

    result = nil
    type = options[:type] || 'both'
    if is_video?
      if type == 'both'
        result = self.extract_still(options.merge(:type => 'poster'))
        self.extract_still(options.merge(:type => 'thumbnail'))
      else
        frame_size = options[:size] || default_frame_sizes[options[:type]]
        ds = self.datastreams[type]
        result = extract_frame(options.merge(:size => frame_size))
        unless options[:preview]
          ds.mimeType = 'image/jpeg'
          ds.content = StringIO.new(result)
        end
      end
      save
    end
    result
  end

  class << self
    def extract_still(pid, options={})
      obj = self.find(pid)
      obj.extract_still(options)
    end
    handle_asynchronously :extract_still
  end

  protected

  def mediainfo
    @mediainfo ||= Mediainfo.new file_location
  end

  def extract_frame(options={})
    if is_video?
      ffmpeg = Avalon::Configuration['ffmpeg']['path']
      frame_size = (options[:size].nil? or options[:size] == 'auto') ? mediainfo.video.streams.first.frame_size : options[:size]

      options[:offset] ||= 2000
      offset = options[:offset].to_i
      unless offset.between?(0,self.duration.to_i)
        raise RangeError, "Offset #{offset} not in range 0..#{self.duration}"
      end
      base = pid.gsub(/:/,'_')

      display_aspect_ratio = mediainfo.video.streams.first.display_aspect_ratio
      if ':'.in? display_aspect_ratio
        (original_width,original_height) = display_aspect_ratio.split(/:/).collect &:to_f
      else
        (original_width,original_height) = [display_aspect_ratio.to_f, display_aspect_ratio.to_f]
      end

      (new_width,new_height) = frame_size.split(/x/).collect &:to_f
      new_height = (new_width/(original_width/original_height)).floor
      new_height += 1 if new_height.odd?
      aspect = new_width/new_height

      Tempfile.open([base,'.jpg']) do |jpeg|
        options = [
          '-ss',      (offset / 1000.0).to_s,
          '-i',       file_location,
          '-s',       "#{new_width.to_i}x#{new_height.to_i}",
          '-vframes', '1',
          '-aspect',  aspect.to_s,
          '-f',       'image2',
          '-y',       jpeg.path
        ]
        Kernel.system(ffmpeg, *options)
        jpeg.rewind
        jpeg.read
      end
    else
      nil
    end
  end

  def calculate_percent_complete matterhorn_response
    totals = {
      :transcode => 70,
      :distribution => 20,
      :cleaning => 0,
      :other => 10
    }

    operations = matterhorn_response.find_by_terms(:operations, :operation).collect { |op|
      type = case op['description']
             when /mp4/ then :transcode
             when /^Distributing/ then :distribution
             else :other
             end
      { :description => op['description'], :state => op['state'], :type => type } 
    }

    result = Hash.new { |h,k| h[k] = 0 }
    operations.each { |op|
      op[:pct] = (totals[op[:type]].to_f / operations.select { |o| o[:type] == op[:type] }.count.to_f).ceil
      state = op[:state].downcase.to_sym 
      result[state] += op[:pct]
      result[:complete] += op[:pct] if END_STATES.include?(op[:state])
    }
    result[:succeeded] += result.delete(:skipped).to_i
    result.each { |k,v| result[k] = 100 if v > 100 }
    result
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
    @mediainfo = nil
    realpath = File.realpath(file.path)
    if !original_name.nil?
      config_path = Avalon::Configuration['matterhorn']['media_path']
      newpath = nil
      if !config_path.nil? and File.directory?(config_path)
        newpath = File.join(Avalon::Configuration['matterhorn']['media_path'], original_name)
        FileUtils.cp(realpath, newpath)
      else
        newpath = File.join(File.dirname(realpath), original_name)
        File.rename(realpath, newpath)
      end
      self.file_location = newpath
    else 
      self.file_location = realpath
    end

    self.duration = begin
      mediainfo.duration.to_s
    rescue
      nil
    end

    self.poster_offset = [2000,mediainfo.duration.to_i].min

    self.file_size = file.size.to_s

    file.close
  end


end
