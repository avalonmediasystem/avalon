# Copyright 2011-2014, The Trustees of Indiana University and Northwestern
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
require 'hooks'
require 'open-uri'
require 'avalon/file_resolver'
require 'avalon/m3u8_reader'

class MasterFile < ActiveFedora::Base
  include ActiveFedora::Associations
  include Hydra::ModelMethods
  include Hydra::AccessControls::Permissions
  include Hooks
  include Rails.application.routes.url_helpers
  include Permalink
  include VersionableModel
  
  WORKFLOWS = ['fullaudio', 'avalon', 'avalon-skip-transcoding', 'avalon-skip-transcoding-audio']

  belongs_to :mediaobject, :class_name=>'MediaObject', :property=>:is_part_of
  has_many :derivatives, :class_name=>'Derivative', :property=>:is_derivation_of

  has_metadata name: 'descMetadata', :type => ActiveFedora::SimpleDatastream do |d|
    d.field :file_location, :string
    d.field :file_checksum, :string
    d.field :file_size, :string
    d.field :duration, :string
    d.field :display_aspect_ratio, :string
    d.field :original_frame_size, :string
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

  has_metadata name: 'masterFile', type: UrlDatastream

  has_attributes :file_checksum, :file_size, :duration, :display_aspect_ratio, :original_frame_size, :file_format, :poster_offset, :thumbnail_offset, datastream: :descMetadata, multiple: false
  has_attributes :workflow_id, :workflow_name, :mediapackage_id, :percent_complete, :percent_succeeded, :percent_failed, :status_code, :operation, :error, :failures, datastream: :mhMetadata, multiple: false

  has_file_datastream name: 'thumbnail'
  has_file_datastream name: 'poster'


  validates :workflow_name, presence: true, inclusion: { in: Proc.new{ WORKFLOWS } }
  validates_each :poster_offset, :thumbnail_offset do |record, attr, value|
    unless value.nil? or value.to_i.between?(0,record.duration.to_i)
      record.errors.add attr, "must be between 0 and #{record.duration}"
    end
  end

  has_model_version 'R3'
  before_save 'update_stills_from_offset!'

  define_hooks :after_processing
  after_processing :post_processing_file_management
  
  after_processing do
    media_object = self.mediaobject
    media_object.set_media_types!
    media_object.set_duration!
    media_object.save(validate: false)
  end

  # First and simplest test - make sure that the uploaded file does not exceed the
  # limits of the system. For now this is hard coded but should probably eventually
  # be set up in a configuration file somewhere
  #
  # 250 MB is the file limit for now
  MAXIMUM_UPLOAD_SIZE = (2**20) * 250

  AUDIO_TYPES = ["audio/vnd.wave", "audio/mpeg", "audio/mp3", "audio/mp4", "audio/wav", "audio/x-wav"]
  VIDEO_TYPES = ["application/mp4", "video/mpeg", "video/mpeg2", "video/mp4", "video/quicktime", "video/avi"]
  UNKNOWN_TYPES = ["application/octet-stream", "application/x-upload-data"]
  QUALITY_ORDER = { "high" => 1, "medium" => 2, "low" => 3 }
  END_STATES = ['STOPPED', 'SUCCEEDED', 'FAILED', 'SKIPPED']
  
  EMBED_SIZE = {:medium => 600}
  AUDIO_HEIGHT = 50

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

  def set_workflow( workflow  = nil )
    if workflow == 'skip_transcoding'
      workflow = case self.file_format
                 when 'Moving image'
                  'avalon-skip-transcoding'
                 when 'Sound' 
                  'avalon-skip-transcoding-audio'
                 else
                  nil
                 end
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
      begin
        Rubyhorn.client.stop(workflow_id)
      rescue Exception => e
        logger.warn "Error stopping workflow: #{e.message}"
      end
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
    if mo.nil?
      logger.warn "MasterFile has no owning MediaObject to update upon deletion"
    else
      mo.save(validate: false)
    end
  end

  def process
    raise "MasterFile is already being processed" if status_code.present? && !finished_processing?
    Delayed::Job.enqueue MatterhornIngestJob.new({
      'url' => "file://" + URI.escape(file_location),
      'title' => pid,
      'flavor' => "presenter/source",
      'filename' => File.basename(file_location),
      'workflow' => self.workflow_name,
    })
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
      embed_code: embed_code(EMBED_SIZE[:medium], {urlappend: '/embed'}), 
      stream_flash: flash, 
      stream_hls: hls 
    }
  end

  def embed_code(width, permalink_opts = {})
    begin
      if self.permalink
        url = self.permalink(permalink_opts)
      else
        url = embed_master_file_path(self.pid, only_path: false, protocol: '//')
      end
      height = is_video? ? (width/display_aspect_ratio.to_f).floor : AUDIO_HEIGHT
      "<iframe src=\"#{url}\" width=\"#{width}\" height=\"#{height}\" frameborder=\"0\" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>"
    rescue 
      ""
    end
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
    current_operation = matterhorn_response.find_by_terms(:operations,:operation).select { |n| n['state'] == 'INSTANTIATED' }.first.try(:[],'description')
    current_operation ||= matterhorn_response.find_by_terms(:operations,:operation).select { |n| ['RUNNING','FAILED','SUCCEEDED'].include?n['state'] }.last.try(:[],'description')
    self.operation = current_operation
    self.error = matterhorn_response.errors.last

    # Because there is no attribute_changed? in AF
    # we want to find out if the duration has changed
    # so we can update it along with the media object.
    if response_duration && response_duration !=  self.duration
      self.duration = response_duration
    end

    save
  end

  def update_progress_on_success!( matterhorn_response )
    # First step is to create derivative objects within Fedora for each
    # derived item. For this we need to pick only those which 
    # have a 'streaming' tag attached
    derivative_data = Hash.new { |h,k| h[k] = {} }
    0.upto(matterhorn_response.streaming_tracks.size-1) { |i|
      track = matterhorn_response.streaming_tracks(i)
      key = track.tags.tag.include?('hls') ? 'hls' : 'rtmp'
      derivative_data[track.tags.quality.first.split('-').last][key] = track
    }

    derivative_data.each_pair do |quality, entries|
      Derivative.create_from_master_file(self, quality, entries, { stream_base: matterhorn_response.stream_base.first })
    end
    
    # Some elements of the original file need to be stored as well even 
    # though they are not being used right now. This includes a checksum 
    # which can be used to validate the file has not changed. 
    self.mediapackage_id = matterhorn_response.mediapackage.id.first
    
    unless matterhorn_response.source_tracks(0).nil?
      self.file_checksum = matterhorn_response.source_tracks(0).checksum.first
    end

    save
    
    run_hook :after_processing
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

  def absolute_location
    masterFile.location
  end

  def absolute_location=(value)
    masterFile.location = value
  end

  def file_location
    descMetadata.file_location.first
  end

  def file_location=(value)
    descMetadata.file_location = value
    if value.blank?
      self.absolute_location = value
    else
      self.absolute_location = Avalon::FileResolver.new.path_to(value) rescue nil
    end
  end

  protected

  def mediainfo
    @mediainfo ||= Mediainfo.new file_location
  end

  def find_frame_source(options={})
    options[:offset] ||= 2000

    response = { source: file_location, offset: options[:offset], master: true }
    unless File.exists?(response[:source])
      Rails.logger.warn("Masterfile `#{file_location}` not found. Extracting via HLS.")
      begin
        token = StreamToken.find_or_create_session_token({media_token:nil}, self.mediapackage_id)
        playlist_url = self.stream_details(token)[:stream_hls].find { |d| d[:quality] == 'high' }[:url]
        playlist = Avalon::M3U8Reader.read(playlist_url)
        details = playlist.at(options[:offset])
        target = File.join(Dir.tmpdir,File.basename(details[:location]))
        File.open(target,'wb') { |f| open(details[:location]) { |io| f.write(io.read) } }
        response = { source: target, offset: details[:offset], master: false }
      ensure
        StreamToken.find_by_token(token).destroy
      end
    end
    return response
  end

  def extract_frame(options={})
    if is_video?
      base = pid.gsub(/:/,'_')
      offset = options[:offset].to_i
      unless offset.between?(0,self.duration.to_i)
        raise RangeError, "Offset #{offset} not in range 0..#{self.duration}"
      end

      ffmpeg = Avalon::Configuration.lookup('ffmpeg.path')
      frame_size = (options[:size].nil? or options[:size] == 'auto') ? self.original_frame_size : options[:size]

      (new_width,new_height) = frame_size.split(/x/).collect &:to_f
      new_height = (new_width/self.display_aspect_ratio.to_f).floor
      new_height += 1 if new_height.odd?
      aspect = new_width/new_height

      frame_source = find_frame_source(offset: offset)
      Tempfile.open([base,'.jpg']) do |jpeg|
        file_source = File.join(File.dirname(jpeg.path),"#{File.basename(jpeg.path,File.extname(jpeg.path))}#{File.extname(frame_source[:source])}")
        File.symlink(frame_source[:source],file_source)
        begin
          options = [
            '-i',       file_source,
            '-ss',      (frame_source[:offset] / 1000.0).to_s,
            '-s',       "#{new_width.to_i}x#{new_height.to_i}",
            '-vframes', '1',
            '-aspect',  aspect.to_s,
            '-f',       'image2',
            '-y',       jpeg.path
          ]
          if frame_source[:master]
            options[0..3] = options.values_at(2,3,0,1)
          end
          Kernel.system(ffmpeg, *options)
          jpeg.rewind
          data = jpeg.read
          Rails.logger.debug("Generated #{data.length} bytes of data")
          if (!frame_source[:master]) and data.length == 0
            # -ss before -i is faster, but fails on some files.
            Rails.logger.warn("No data received. Swapping -ss and -i options")
            options[0..3] = options.values_at(2,3,0,1)
            Kernel.system(ffmpeg, *options)
            jpeg.rewind
            data = jpeg.read
            Rails.logger.debug("Generated #{data.length} bytes of data")
          end
          data
        ensure
          File.unlink(file_source)
        end
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
      op[:pct] = (totals[op[:type]].to_f / operations.select { |o| o[:type] == op[:type] }.count.to_f)
      state = op[:state].downcase.to_sym 
      result[state] += op[:pct]
      result[:complete] += op[:pct] if END_STATES.include?(op[:state])
    }
    result[:succeeded] += result.delete(:skipped) unless result[:skipped].nil?
    result.each {|k,v| result[k] = result[k].round }
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
    if original_name.present?
      config_path = Avalon::Configuration.lookup('matterhorn.media_path')
      newpath = nil
      if config_path.present? and File.directory?(config_path)
        newpath = File.join(config_path, original_name)
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
  
    unless mediainfo.video.streams.empty?
      display_aspect_ratio_s = mediainfo.video.streams.first.display_aspect_ratio
      if ':'.in? display_aspect_ratio_s
        self.display_aspect_ratio = display_aspect_ratio_s.split(/:/).collect(&:to_f).reduce(:/).to_s
      else
        self.display_aspect_ratio = display_aspect_ratio_s
      end
      self.original_frame_size = mediainfo.video.streams.first.frame_size
      self.poster_offset = [2000,mediainfo.duration.to_i].min
    end

    self.file_size = file.size.to_s

    file.close
  end

  def post_processing_file_management
    logger.debug "Finished processing"

    case Avalon::Configuration.lookup('master_file_management.strategy')
    when 'delete'
      AvalonJobs.delete_masterfile self.pid
    when 'move'
      move_path = Avalon::Configuration.lookup('master_file_management.path')
      raise '"path" configuration missing for master_file_management strategy "move"' if move_path.blank?
      newpath = File.join(move_path, post_processing_move_filename(file_location, pid: self.pid))
      AvalonJobs.move_masterfile self.pid, newpath
    else
      # Do nothing
    end
  end

  def post_processing_move_filename(oldpath, options={})
    "#{options[:pid].gsub(":","_")}-#{File.basename(oldpath)}"
  end

end
