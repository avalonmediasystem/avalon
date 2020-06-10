# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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
  # TODO: Do we need permissions on master files?
  # include Hydra::AccessControls::Permissions
  include Hooks
  include Rails.application.routes.url_helpers
  include Permalink
  include FrameSize
  include Identifier
  include MigrationTarget
  include MasterFileBehavior
  include MasterFileIntercom

  belongs_to :media_object, class_name: 'MediaObject', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
  has_many :derivatives, class_name: 'Derivative', predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isDerivationOf, dependent: :destroy

  has_subresource 'structuralMetadata', class_name: 'StructuralMetadata' do |f|
    f.original_name = 'structuralMetadata.xml'
  end

  has_subresource 'thumbnail', class_name: 'IndexedFile' do |f|
    f.original_name = 'thumbnail.jpg'
  end

  has_subresource 'poster', class_name: 'IndexedFile' do |f|
    f.original_name = 'poster.jpg'
  end

  # Don't pass the block here since we save the original_name when the user uploads the captions file
  has_subresource 'captions', class_name: 'IndexedFile'

  has_subresource 'waveform', class_name: 'IndexedFile' do |f|
    f.original_name = 'waveform.json'
  end

  property :title, predicate: ::RDF::Vocab::EBUCore.title, multiple: false do |index|
    index.as :stored_searchable
  end
  property :file_location, predicate: ::RDF::Vocab::EBUCore.locator, multiple: false do |index|
    index.as :stored_sortable
  end
  property :file_checksum, predicate: ::RDF::Vocab::NFO.hashValue, multiple: false do |index|
    index.as :stored_sortable
  end
  property :file_size, predicate: ::RDF::Vocab::EBUCore.fileSize, multiple: false # indexed in to_solr
  property :duration, predicate: ::RDF::Vocab::EBUCore.duration, multiple: false do |index|
    index.as :stored_sortable
  end
  property :display_aspect_ratio, predicate: ::RDF::Vocab::EBUCore.aspectRatio, multiple: false do |index|
    index.as :stored_sortable
  end
  frame_size_property :original_frame_size, predicate: Avalon::RDFVocab::Common.resolution, multiple: false do |index|
    index.as :stored_sortable
  end
  property :file_format, predicate: ::RDF::Vocab::PREMIS.hasFormatName, multiple: false do |index|
    index.as :stored_sortable
  end
  property :poster_offset, predicate: Avalon::RDFVocab::MasterFile.posterOffset, multiple: false do |index|
    index.as :stored_sortable
  end
  property :thumbnail_offset, predicate: Avalon::RDFVocab::MasterFile.thumbnailOffset, multiple: false do |index|
    index.as :stored_sortable
  end
  property :date_digitized, predicate: ::RDF::Vocab::EBUCore.dateCreated, multiple: false do |index|
    index.as :stored_sortable
  end
  property :physical_description, predicate: ::RDF::Vocab::EBUCore.hasFormat, multiple: false do |index|
    index.as :stored_sortable
  end
  property :masterFile, predicate: ::RDF::Vocab::EBUCore.filename, multiple: false
  property :identifier, predicate: ::RDF::Vocab::Identifiers.local, multiple: true do |index|
    index.as :symbol
  end
  property :comment, predicate: ::RDF::Vocab::EBUCore.comments, multiple: true do |index|
    index.as :stored_searchable
  end

  # Workflow status properties
  property :workflow_id, predicate: Avalon::RDFVocab::Transcoding.workflowId, multiple: false do |index|
    index.as :stored_sortable
  end
  property :encoder_classname, predicate: Avalon::RDFVocab::Transcoding.encoderClassname, multiple: false do |index|
    index.as :stored_sortable
  end
  property :workflow_name, predicate: Avalon::RDFVocab::Transcoding.workflowName, multiple: false do |index|
    index.as :stored_sortable
  end

  # Delegated to EncodeRecord
  def encode_record
    return nil unless workflow_id
    gid = "gid://ActiveEncode/#{encoder_class}/#{workflow_id}"
    # @encode_record ||= ActiveEncode::EncodeRecord.find_by(global_id: gid)
    ActiveEncode::EncodeRecord.find_by(global_id: gid)
  end

  def raw_encode_record
    return nil unless encode_record
    # @raw_encode_record ||= JSON.parse(encode_record.raw_object)
    JSON.parse(encode_record.raw_object)
  end

  def status_code
    return nil unless encode_record
    encode_record.state.to_s.upcase
  end

  def percent_complete
    return nil unless encode_record
    encode_record.progress.to_s
  end

  def operation
    return nil unless encode_record
    raw_encode_record['current_operations']&.first
  end

  def error
    return nil unless encode_record
    raw_encode_record['errors'].first
  end

  # For working file copy when Settings.encoding.working_file_path is set
  property :working_file_path, predicate: Avalon::RDFVocab::MasterFile.workingFilePath, multiple: true

  validates :workflow_name, presence: true, inclusion: { in: proc { WORKFLOWS } }
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
  # validates :file_format, presence: true, exclusion: { in: ['Unknown'], message: "The file was not recognized as audio or video." }

  after_save :update_stills_from_offset!, if: Proc.new { |mf| mf.previous_changes.include?("poster_offset") || mf.previous_changes.include?("thumbnail_offset") }
  before_destroy :stop_processing!
  before_destroy :update_parent!
  define_hooks :after_transcoding, :after_processing

  # Generate the waveform after proessing is complete but before master file management
  after_transcoding :generate_waveform
  after_transcoding :update_ingest_batch

  after_processing :post_processing_file_management

  # First and simplest test - make sure that the uploaded file does not exceed the
  # limits of the system. For now this is hard coded but should probably eventually
  # be set up in a configuration file somewhere
  #
  # 250 MB is the file limit for now
  MAXIMUM_UPLOAD_SIZE = Settings.max_upload_size || 2.gigabytes

  WORKFLOWS = ['fullaudio', 'avalon', 'pass_through', 'avalon-skip-transcoding', 'avalon-skip-transcoding-audio'].freeze
  AUDIO_TYPES = ["audio/vnd.wave", "audio/mpeg", "audio/mp3", "audio/mp4", "audio/wav", "audio/x-wav"]
  VIDEO_TYPES = ["application/mp4", "video/mpeg", "video/mpeg2", "video/mp4", "video/quicktime", "video/avi"]
  UNKNOWN_TYPES = ["application/octet-stream", "application/x-upload-data"]
  END_STATES = ['CANCELLED', 'COMPLETED', 'FAILED']
  QUALITY_ORDER = { 'quality-high' => 3, 'quality-medium' => 2, 'quality-low' => 1 }.freeze

  def save_parent
    unless media_object.nil?
      media_object.save
    end
  end

  def setContent(file)
    case file
    when Hash #Multiple files for pre-transcoded derivatives
      saveDerivativesHash(file)
    when ActionDispatch::Http::UploadedFile #Web upload
      saveOriginal(file, file.original_filename)
    when URI, Addressable::URI
      case file.scheme
      when 'file'
        saveOriginal(File.open(file.path), File.basename(file.path))
      when 's3'
        self.file_location = file.to_s
        self.file_size = FileLocator::S3File.new(file).object.size
      end
    else #Batch
      saveOriginal(file, File.basename(file.path))
    end
    reloadTechnicalMetadata!
  end

  def set_workflow( workflow  = nil )
    if workflow == 'skip_transcoding'
      workflow = 'pass_through'
    elsif self.file_format == 'Sound'
      workflow = 'fullaudio'
    elsif self.file_format == 'Moving image'
      workflow = 'avalon'
    else
      logger.warn "Could not find workflow for: #{self}"
    end
    self.workflow_name = workflow
  end

  alias_method :'_media_object=', :'media_object='

  # This requires the MasterFile having an actual id
  def media_object=(mo)
    # Removes existing association
    if self.media_object.present?
      self.media_object.master_files = self.media_object.master_files.to_a.reject { |mf| mf.id == self.id }
      self.media_object.ordered_master_files = self.media_object.ordered_master_files.to_a.reject { |mf| mf.id == self.id }
      self.media_object.save
    end

    self._media_object=(mo)
    unless self.media_object.nil?
      self.media_object.ordered_master_files += [self]
      self.media_object.save
    end
  end

  def process file=nil
    raise "MasterFile is already being processed" if status_code.present? && !finished_processing?

    return process_pass_through(file) if self.workflow_name == 'pass_through'

    ActiveEncodeJobs::CreateEncodeJob.perform_later(input_path, id)
  end

  def process_pass_through(file)
    options = {}
    input = nil
    # Options hash: { outputs: [{ label: 'low',  url: 'file:///derivatives/low.mp4' }, { label: 'high', url: 'file:///derivatives/high.mp4' }]}
    if file.is_a? Hash
      input = file.sort_by { |f| QUALITY_ORDER[f[0]] }.last[1].path
      options[:outputs] = file.collect { |quality, f| { label: quality.remove("quality-"), url: FileLocator.new(f.to_path).uri.to_s } }
    else
      #Build hash for single file skip transcoding
      input = input_path
      options[:outputs] = [{ label: 'high', url: input }]
    end

    ActiveEncodeJobs::CreateEncodeJob.perform_later(input, id, options)
  end

  def input_path
    if working_file_path.present?
      FileLocator.new(working_file_path.first).uri.to_s
    else
      FileLocator.new(file_location).uri.to_s
    end
  end

  def finished_processing?
    END_STATES.include?(status_code)
  end

  def update_progress_on_success!(encode)
    #Set date ingested to now if it wasn't preset (by batch, for example)
    #TODO pull this from the encode
    self.date_digitized ||= Time.now.utc.iso8601

    outputs = Array(encode.output).collect do |output|
      {
        id: output.id,
        label: output.label,
        url: output.url,
        duration: output.duration,
        # TODO: add support for mime_type to ActiveEncode?
        # mime_type: output.mime_type,
        audio_bitrate: output.audio_bitrate,
        audio_codec: output.audio_codec,
        video_bitrate: output.video_bitrate,
        video_codec: output.video_codec,
        width: output.width,
        height: output.height
      }
    end
    update_derivatives(outputs)
    run_hook :after_transcoding
  end

  def update_derivatives(outputs, managed = true)
    outputs.each do |output|
      quality = output[:label]
      existing = derivatives.to_a.find { |d| d.quality == quality }
      d = Derivative.from_output(output, managed)
      d.master_file = self
      if d.save && existing
        existing.delete
      end
    end

    save
  end

  alias_method :'_poster_offset', :'poster_offset'
  def poster_offset
    _poster_offset.to_i
  end

  alias_method :'_thumbnail_offset', :'thumbnail_offset'
  def thumbnail_offset
    _thumbnail_offset.to_i
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

    self.send("_#{type}_offset=".to_sym,milliseconds.to_s)
    milliseconds
  end

  def update_stills_from_offset!
    # Update stills together
    ExtractStillJob.perform_later(self.id, :type => 'both', :offset => self.poster_offset)

    # Update stills independently
    # @stills_to_update.each do |type|
    #   self.class.extract_still(self.id, :type => type, :offset => self.send("#{type}_offset"))
    # end
  end

  def extract_still(options={})
    default_frame_sizes = {
      'poster'    => '1280x720',
      'thumbnail' => '640x360'
    }

    result = nil
    type = options[:type] || 'both'
    if is_video?
      if type == 'both'
        result = self.extract_still(options.merge(:type => 'poster'))
        self.extract_still(options.merge(:type => 'thumbnail'))
      else
        frame_size = options[:size] || default_frame_sizes[options[:type]]
        file = self.send(type.to_sym)
        result = extract_frame(options.merge(:size => frame_size))
        unless options[:preview]
          file.mime_type = 'image/jpeg'
          file.content = StringIO.new(result)
        end
      end
    end
    result
  end

  def absolute_location
    masterFile
  end

  def absolute_location=(value)
    self.masterFile = value
  end

  def file_location=(value)
    file_location_will_change!
    resource.file_location = value
    if value.blank?
      self.absolute_location = value
    else
      self.absolute_location = Avalon::FileResolver.new.path_to(value) rescue nil
    end
  end

  def encoder_class
    find_encoder_class(encoder_classname) ||
      find_encoder_class("#{workflow_name}_encode".classify) ||
      find_encoder_class((Settings.encoding.engine_adapter + "_encode").classify) ||
      MasterFile.default_encoder_class ||
      WatchedEncode
  end

  def encoder_class=(value)
    if value.nil?
      self.encoder_classname = nil
    elsif value.is_a?(Class) and value.ancestors.include?(ActiveEncode::Base)
      self.encoder_classname = value.name
    else
      raise ArgumentError, '#encoder_class must be a descendant of ActiveEncode::Base'
    end
  end

  def self.default_encoder_class
    @@default_encoder_class ||= nil
  end

  def self.default_encoder_class=(value)
    if value.nil?
      @@default_encoder_class = nil
    elsif value.is_a?(Class) and value.ancestors.include?(ActiveEncode::Base)
      @@default_encoder_class = value
    else
      raise ArgumentError, '#default_encoder_class must be a descendant of ActiveEncode::Base'
    end
  end

  def structural_metadata_labels
    structuralMetadata.xpath('//@label').collect{|a|a.value}
  end

  # Supplies the route to the master_file as an rdf formatted URI
  # @return [String] the route as a uri
  # @example uri for a mf on avalon.iu.edu with a id of: avalon:1820
  #   "my_master_file.rdf_uri" #=> "https://www.avalon.iu.edu/master_files/avalon:1820"
  def rdf_uri
    master_file_url(id)
  end

  # Returns the dctype of the master_file
  # @return [String] either 'dctypes:MovingImage' or 'dctypes:Sound'
  def rdf_type
    is_video? ? 'dctypes:MovingImage' : 'dctypes:Sound'
  end

  def self.post_processing_move_filename(oldpath, options = {})
    prefix = options[:id].tr(':', '_')
    if File.basename(oldpath).start_with?(prefix)
      File.basename(oldpath)
    else
      "#{prefix}-#{File.basename(oldpath)}"
    end
  end

  def has_audio?
    # The MasterFile doesn't have an audio track unless the first derivative does
    # This is useful to skip unnecessary waveform generation
    derivatives.any?(&:audio_codec)
  end

  def has_poster?
    !poster.empty?
  end

  def has_thumbnail?
    !thumbnail.empty?
  end

  def has_captions?
    !captions.empty?
  end

  def caption_type
    has_captions? ? captions.mime_type : nil
  end

  def has_waveform?
    !waveform.empty?
  end

  def waveform_type
    has_waveform? ? waveform.mime_type : nil
  end

  def has_structuralMetadata?
    structuralMetadata.present? && Nokogiri::XML(structuralMetadata.content).xpath('//Item').present?
  end

  def to_solr *args
    super.tap do |solr_doc|
      solr_doc['file_size_ltsi'] = file_size
      solr_doc['has_captions?_bs'] = has_captions?
      solr_doc['has_waveform?_bs'] = has_waveform?
      solr_doc['has_poster?_bs'] = has_poster?
      solr_doc['has_thumbnail?_bs'] = has_thumbnail?
      solr_doc['has_structuralMetadata?_bs'] = has_structuralMetadata?
      solr_doc['caption_type_ss'] = caption_type
      solr_doc['identifier_ssim'] = identifier.map(&:downcase)

      solr_doc['percent_complete_ssi'] = percent_complete
      # solr_doc['percent_succeeded_ssi'] =  percent_succeeded
      # solr_doc['percent_failed_ssi'] = percent_failed
      solr_doc['status_code_ssi'] = status_code
      solr_doc['operation_ssi'] = operation
      solr_doc['error_ssi'] = error
    end
  end

  def create_working_file!(full_path)
    working_path = MasterFile.calculate_working_file_path(full_path)
    return unless working_path.present?

    self.working_file_path = [working_path]
    FileUtils.mkdir(File.dirname(working_path))
    FileUtils.cp(full_path, working_path)
    working_path
  end

  def self.calculate_working_file_path(old_path)
    config_path = Settings&.encoding&.working_file_path
    if config_path.present? && File.directory?(config_path)
      File.join(config_path, SecureRandom.uuid, File.basename(old_path))
    else
      nil
    end
  end

  protected

  def mediainfo
    if @mediainfo.nil?
      @mediainfo = Mediainfo.new(FileLocator.new(file_location).location)
    end
    @mediainfo
  end

  def find_frame_source(options={})
    options[:offset] ||= 2000

    source = FileLocator.new(working_file_path&.first || file_location)
    options[:master] = true
    if source.source.nil? or (source.uri.scheme == 's3' and not source.exist?)
      source = FileLocator.new(self.derivatives.where(quality_ssi: 'high').first.absolute_location)
      options[:master] = false
    end
    response = { source: source&.location }.merge(options)
    return response if response[:source].to_s =~ %r(^https?://)

    unless File.exists?(response[:source])
      Rails.logger.warn("Masterfile `#{file_location}` not found. Extracting via HLS.")
      begin
        playlist_url = self.stream_details[:stream_hls].find { |d| d[:quality] == 'high' }[:url]
        secure_url = SecurityHandler.secure_url(playlist_url, target: self.id)
        playlist = Avalon::M3U8Reader.read(secure_url)
        details = playlist.at(options[:offset])

        # Fixes https://github.com/avalonmediasystem/avalon/issues/3474
        target_location = File.basename(details[:location]).split('?')[0]
        target = File.join(Dir.tmpdir, target_location)
        File.open(target,'wb') { |f| open(details[:location]) { |io| f.write(io.read) } }
        response = { source: target, offset: details[:offset], master: false }
      end
    end
    return response
  end

  def extract_frame(options={})
    return unless is_video?

    offset = options[:offset].to_i
    unless offset.between?(0,self.duration.to_i)
      raise RangeError, "Offset #{offset} not in range 0..#{self.duration}"
    end

    frame_size = (options[:size].nil? or options[:size] == 'auto') ? self.original_frame_size : options[:size]

    (new_width,new_height) = frame_size.split(/x/).collect(&:to_f)
    new_height = (new_width/self.display_aspect_ratio.to_f).round
    frame_source = find_frame_source(offset: offset)
    data = get_ffmpeg_frame_data(frame_source, new_width, new_height)
    raise RuntimeError, "Frame extraction failed. See log for details." if data.empty?
    data
  end

  def get_ffmpeg_frame_data frame_source, new_width, new_height
    ffmpeg = Settings.ffmpeg.path
    unless File.executable?(ffmpeg)
      raise RuntimeError, "FFMPEG not at configured location: #{ffmpeg}"
    end
    base = id.gsub(/\//,'_')
    aspect = new_width/new_height
    Tempfile.open([base,'.jpg']) do |jpeg|
      file_source = frame_source[:source]
      unless file_source =~ %r(https?://)
        file_source = File.join(File.dirname(jpeg.path),"#{File.basename(jpeg.path,File.extname(jpeg.path))}#{File.extname(frame_source[:source])}")
        File.symlink(frame_source[:source],file_source)
      end
      begin
        options = [
          '-i',       file_source,
          '-ss',      (frame_source[:offset] / 1000.0).to_s,
          '-s',       "#{new_width.to_i}x#{new_height.to_i}",
          '-vframes', '1',
          '-aspect',  aspect.to_s,
          '-q:v',       '4',
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
        File.unlink file_source unless file_source.match? %r{https?://}
        File.unlink frame_source[:source] unless frame_source[:master] or frame_source[:source].match? %r{https?://}
        File.unlink jpeg
      end
    end
  end

  def saveOriginal(file, original_name=nil)
    realpath = File.realpath(file.path)

    if original_name.present?
      # If we have a temp name from an upload, rename to the original name supplied by the user
      unless File.basename(realpath) == original_name
        path = File.join(File.dirname(realpath), original_name)
        File.rename(realpath, path)
        realpath = path
      end

      create_working_file!(realpath)
    end
    self.file_location = realpath
    self.file_size = file.size.to_s
  ensure
    file.close
  end

  def saveDerivativesHash(derivative_hash)
    usable_files = derivative_hash.select { |quality, file| File.file?(file) }
    self.working_file_path = usable_files.values.collect { |file| create_working_file!(File.realpath(file)) }.compact

    %w(quality-high quality-medium quality-low).each do |quality|
      next unless usable_files.has_key?(quality)
      self.file_location = File.realpath(usable_files[quality])
      self.file_size = usable_files[quality].size.to_s
      break
    end
  ensure
    derivative_hash.values.map { |file| file.close }
  end

  def reloadTechnicalMetadata!
    #Reset mediainfo
    @mediainfo = nil

    # Formats like MP4 can be caught as both audio and video
    # so the case statement flows in the preferred order
    self.file_format = if mediainfo.video?
                         'Moving image'
                       elsif mediainfo.audio?
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
      self.poster_offset = [2000,self.duration.to_i].min
    end
  end

  def post_processing_file_management
    logger.debug "Finished processing"

    # Run master file management strategy
    manage_master_file
    # Clean up working file if it exists
    CleanupWorkingFileJob.perform_later(id, working_file_path.to_a) unless Settings&.encoding&.working_file_path.blank?
  end

  def update_ingest_batch
    ingest_batch = IngestBatch.find_ingest_batch_by_media_object_id( self.media_object.id )
    if ingest_batch && ! ingest_batch.email_sent? && ingest_batch.finished?
      IngestBatchMailer.status_email(ingest_batch.id).deliver_later
      ingest_batch.email_sent = true
      ingest_batch.save!
    end
  end

  def find_encoder_class(klass_name)
    klass = klass_name&.safe_constantize
    klass if klass&.ancestors&.include?(ActiveEncode::Base)
  end

  def stop_processing!
    # Stops all processing
    ActiveEncodeJobs::CancelEncodeJob.perform_later(workflow_id, id) if workflow_id.present? && finished_processing?
  end

  def update_parent!
    return unless media_object.present?
    media_object.master_files.delete(self)
    media_object.ordered_master_files.delete(self)
    media_object.set_media_types!
    media_object.set_duration!
    if !media_object.save
      logger.error "Failed when updating media object #{media_object.id} while destroying master file #{self.id}"
    end
  end

  private

  def generate_waveform
    WaveformJob.perform_later(id)
  rescue StandardError => e
    logger.warn("WaveformJob failed: #{e.message}")
    logger.warn(e.backtrace.to_s)
  end

  def manage_master_file
    case Settings.master_file_management.strategy
    when 'delete'
      MasterFileManagementJobs::Delete.perform_later self.id
    when 'move'
      move_path = Settings.master_file_management.path
      raise '"path" configuration missing for master_file_management strategy "move"' if move_path.blank?
      newpath = File.join(move_path, MasterFile.post_processing_move_filename(file_location, id: id))
      MasterFileManagementJobs::Move.perform_later self.id, newpath
    else
      # Do nothing
    end
  end
end
