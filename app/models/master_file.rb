# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

  has_metadata name: "structuralMetadata", :type => StructuralMetadata

  WORKFLOWS = ['fullaudio', 'avalon', 'avalon-skip-transcoding', 'avalon-skip-transcoding-audio']

  belongs_to :mediaobject, :class_name=>'MediaObject', :property=>:is_part_of
  has_many :derivatives, :class_name=>'Derivative', :property=>:is_derivation_of

  has_metadata name: 'descMetadata', :type => CachingSimpleDatastream.create(self) do |d|
    d.field :file_location, :string
    d.field :file_checksum, :string
    d.field :file_size, :string
    d.field :duration, :string
    d.field :display_aspect_ratio, :string
    d.field :original_frame_size, :string
    d.field :file_format, :string
    d.field :poster_offset, :string
    d.field :thumbnail_offset, :string
    d.field :date_digitized, :string
    d.field :physical_description, :string
  end

  has_metadata name: 'mhMetadata', :type => CachingSimpleDatastream.create(self) do |d|
    d.field :workflow_id, :string
    d.field :workflow_name, :string
    d.field :percent_complete, :string
    d.field :percent_succeeded, :string
    d.field :percent_failed, :string
    d.field :status_code, :string
    d.field :operation, :string
    d.field :error, :string
    d.field :failures, :string
    d.field :encoder_classname, :string
  end

  has_metadata name: 'masterFile', type: UrlDatastream

  has_attributes :file_location, :physical_description, :file_checksum, :file_size, :duration, :display_aspect_ratio, :original_frame_size, :file_format, :poster_offset, :thumbnail_offset, :date_digitized, datastream: :descMetadata, multiple: false
  has_attributes :workflow_id, :workflow_name, :encoder_classname, :percent_complete, :percent_succeeded, :percent_failed, :status_code, :operation, :error, :failures, datastream: :mhMetadata, multiple: false

  has_file_datastream name: 'thumbnail'
  has_file_datastream name: 'poster'
  has_file_datastream name: 'captions'

  validates :workflow_name, presence: true, inclusion: { in: Proc.new{ WORKFLOWS } }
  validates_each :date_digitized do |record, attr, value|
    unless value.nil?
      begin
        Time.parse(value)
      rescue Exception => err
        record.errors.add attr, err.message
      end
    end
  end
  validates_each :poster_offset, :thumbnail_offset do |record, attr, value|
    unless value.nil? or value.to_i.between?(0,record.duration.to_i)
      record.errors.add attr, "must be between 0 and #{record.duration}"
    end
  end
  #validates :file_format, presence: true, exclusion: { in: ['Unknown'], message: "The file was not recognized as audio or video." }

  has_model_version 'R3'
  before_save :update_stills_from_offset!

  define_hooks :after_processing

  after_processing :post_processing_file_management
  after_processing :update_ingest_batch

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
  END_STATES = ['CANCELLED', 'COMPLETED', 'FAILED']

  EMBED_SIZE = {:medium => 600}
  AUDIO_HEIGHT = 50

  def save_parent
    unless mediaobject.nil?
      mediaobject.save(validate: false)
    end
  end

  def setContent(file)
    case file
    when Hash #Multiple files for pre-transcoded derivatives
      saveOriginal( (file.has_key?('quality-high') && File.file?( file['quality-high'] )) ? file['quality-high'] : (file.has_key?('quality-medium') && File.file?( file['quality-medium'] )) ? file['quality-medium'] : file.values[0] )
      file.each_value {|f| f.close unless f.closed? }
    when ActionDispatch::Http::UploadedFile #Web upload
      saveOriginal(file, file.original_filename)
    else #Batch or dropbox
      saveOriginal(file)
    end
    reloadTechnicalMetadata!
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

  def destroy
    mo = self.mediaobject
    self.mediaobject = nil

    # Stops all processing
    if workflow_id.present? && !finished_processing?
      encoder_class.find(workflow_id).cancel!
    end
    self.derivatives.map(&:destroy)

    clear_association_cache

    super

    #Only save the media object if the master file was successfully deleted
    if mo.nil?
      logger.warn "MasterFile has no owning MediaObject to update upon deletion"
    else
      mo.save(validate: false)
    end
  end

  def process file=nil
    raise "MasterFile is already being processed" if status_code.present? && !finished_processing?

    #Build hash for single file skip transcoding
    if !file.is_a?(Hash) && (self.workflow_name == 'avalon-skip-transcoding' || self.workflow_name == 'avalon-skip-transcoding-audio')
      file = {'quality-high' => File.new(file_location)}
    end

    input = if file.is_a? Hash
      file_dup = file.dup
      file_dup.each_pair {|quality, f| file_dup[quality] = "file://" + URI.escape(File.realpath(f.to_path))}
    else
      "file://" + URI.escape(file_location)
    end

    Delayed::Job.enqueue ActiveEncodeJob::Create.new(self.id, encoder_class.new(input, preset: self.workflow_name))
  end

  def status?(value)
    status_code == value
  end

  def failed?
    status?('FAILED')
  end

  def succeeded?
    status?('COMPLETED')
  end

  def stream_details(token,host=nil)
    flash, hls = [], []
    ActiveFedora::SolrService.reify_solr_results(derivatives.load_from_solr, load_from_solr: true).each do |d|
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
    captions_path = Rails.application.routes.url_helpers.captions_master_file_path(self) unless captions.empty?
    captions_format = self.captions.mimeType

    # Returns the hash
    {
      id: self.pid,
      label: label,
      is_video: is_video?,
      poster_image: poster_path,
      embed_code: embed_code(EMBED_SIZE[:medium], {urlappend: '/embed'}),
      stream_flash: flash,
      stream_hls: hls,
      captions_path: captions_path,
      captions_format: captions_format,
      duration: (duration.to_f / 1000).round,
      embed_title: embed_title
    }
  end

  def embed_title
    "#{ self.mediaobject.title } - #{ self.label || self.file_location.split( "/" ).last }"
  end

  def embed_code(width, permalink_opts = {})
    begin
      if self.permalink
        url = self.permalink(permalink_opts)
      else
        url = embed_master_file_path(self.pid, only_path: false, protocol: '//')
      end
      height = is_video? ? (width/display_aspect_ratio.to_f).floor : AUDIO_HEIGHT
      "<iframe title=\"#{ embed_title }\" src=\"#{url}\" width=\"#{width}\" height=\"#{height}\" frameborder=\"0\" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>"
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

  def update_progress!
    update_progress_with_encode!(encoder_class.find(self.workflow_id))
  end

  def update_progress_with_encode!(encode)
    self.operation = encode.current_operations.first if encode.current_operations.present?
    self.percent_complete = encode.percent_complete.to_s
    self.percent_succeeded = encode.percent_complete.to_s
    self.error = encode.errors.first if encode.errors.present?
    self.status_code = encode.state.to_s.upcase
    self.duration = encode.tech_metadata[:duration] if encode.tech_metadata[:duration]
    self.file_checksum = encode.tech_metadata[:checksum] if encode.tech_metadata[:checksum]
    self.workflow_id = encode.id
    #self.workflow_name = encode.options[:preset] #MH can switch to an error workflow

    case self.status_code
    when"COMPLETED"
      self.percent_complete = encode.percent_complete.to_s
      self.percent_succeeded = encode.percent_complete.to_s
      self.percent_failed = 0.to_s
      self.update_progress_on_success!(encode)
    when "FAILED"
      self.percent_complete = encode.percent_complete.to_s
      self.percent_succeeded = encode.percent_complete.to_s
      self.percent_failed = (100 - encode.percent_complete).to_s
    end
    self
  end

  def update_progress_on_success!(encode)
    #Set date ingested to now if it wasn't preset (by batch, for example)
    #TODO pull this from the encode
    self.date_digitized ||= Time.now.utc.iso8601

    update_derivatives(encode.output)
    run_hook :after_processing
  end

  def update_derivatives(output,managed=true)
    outputs_by_quality = output.group_by {|o| o[:label]}

    outputs_by_quality.each_pair do |quality, outputs|
      existing = derivatives.to_a.find {|d| d.encoding.quality.first == quality}
      d = Derivative.from_output(outputs,managed)
      d.masterfile = self
      if d.save && existing
        existing.delete
      end
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

  def absolute_location
    masterFile.location
  end

  def absolute_location=(value)
    masterFile.location = value
  end

  def file_location=(value)
    file_location_will_change!
    descMetadata.file_location = value
    if value.blank?
      self.absolute_location = value
    else
      self.absolute_location = Avalon::FileResolver.new.path_to(value) rescue nil
    end
  end

  def encoder_class
    find_encoder_class(encoder_classname) || find_encoder_class(workflow_name.to_s.classify) || ActiveEncode::Base
  end

  def encoder_class=(value)
    if value.nil?
      mhMetadata.encoder_classname = nil
    elsif value.is_a?(Class) and value.ancestors.include?(ActiveEncode::Base)
      mhMetadata.encoder_classname = value.name
    else
      raise ArgumentError, '#encoder_class must be a descendant of ActiveEncode::Base'
    end
  end

  def structural_metadata_labels
    structuralMetadata.xpath('//@label').collect{|a|a.value}
  end

  # Supplies the route to the master_file as an rdf formatted URI
  # @return [String] the route as a uri
  # @example uri for a mf on avalon.iu.edu with a pid of: avalon:1820
  #   "my_masterfile.rdf_uri" #=> "https://www.avalon.iu.edu/master_files/avalon:1820"
  def rdf_uri
    master_file_url(pid)
  end

  # Returns the dctype of the master_file
  # @return [String] either 'dctypes:MovingImage' or 'dctypes:Sound'
  def rdf_type
    is_video? ? 'dctypes:MovingImage' : 'dctypes:Sound'
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
        token = StreamToken.find_or_create_session_token({media_token:nil}, self.pid)
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

  def saveOriginal(file, original_name=nil)
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
    self.file_size = file.size.to_s
    file.close
  end

  def reloadTechnicalMetadata!
    #Reset mediainfo
    @mediainfo = nil

    # Formats like MP4 can be caught as both audio and video
    # so the case statement flows in the preferred order
    self.file_format = case
                    when mediainfo.video?
                      'Moving image'
                    when mediainfo.audio?
                       'Sound'
                    else
                       'Unknown'
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
    prefix = options[:pid].gsub(":","_")
    if oldpath.start_with?(prefix)
      oldpath
    else
      "#{prefix}-#{File.basename(oldpath)}"
    end
  end

  def update_ingest_batch
    ingest_batch = IngestBatch.find_ingest_batch_by_media_object_id( self.mediaobject.id )
    if ingest_batch && ! ingest_batch.email_sent? && ingest_batch.finished?
      IngestBatchMailer.status_email(ingest_batch.id).deliver
      ingest_batch.email_sent = true
      ingest_batch.save!
    end
  end

  def find_encoder_class(klass_name)
    ActiveEncode::Base.descendants.find { |c| c.name == klass_name }
  end
end
