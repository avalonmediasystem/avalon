# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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


require 'active_model'

module Avalon
  module Batch
    class Entry
      extend ActiveModel::Translation

      attr_reader :fields, :files, :opts, :row, :errors, :manifest, :collection

      def initialize(fields, files, opts, row, manifest)
        @fields = fields || opts[:fields]
        @files  = files || opts[:files]
        @row    = row || opts[:position]
        @manifest = manifest || opts[:manifest]
        # The next two depend on the manifest but it isn't available until after initialization hence the accessors below.
        @user_key = opts[:user_key]
        @collection = opts[:collection]
        @opts   = opts.except(:fields, :files, :position, :manifest, :user_key, :collection)
        @errors = ActiveModel::Errors.new(self)
      end

      def media_object
        @media_object ||= MediaObject.new(avalon_uploader: user_key, collection: collection).tap do |mo|
          mo.workflow.origin = 'batch'
          mo.workflow.last_completed_step = HYDRANT_STEPS.last.step
          if Avalon::BibRetriever.configured?(fields[:bibliographic_id_label]) && fields[:bibliographic_id].present?
            begin
              mo.descMetadata.populate_from_catalog!(fields[:bibliographic_id].first, Array(fields[:bibliographic_id_label]).first)
            rescue Exception => e
              @errors.add(:bibliographic_id, e.message)
            end
          else
            begin
              mo.assign_attributes(media_object_fields)
            rescue ActiveFedora::UnknownAttributeError => e
              @errors.add(e.attribute.to_sym, e.message)
            end
          end
        end
        # Not quite sure why this doesn't work within the tap and had to move it here
        @media_object.hidden = hidden
        @media_object
      end

      def to_json
        json_hash = opts
        json_hash[:fields] = fields
        json_hash[:files] = files
        json_hash[:position] = row
        json_hash[:user_key] = user_key
        json_hash[:collection] = collection.id
        json_hash.to_json
      end

      def self.from_json(json)
        json_hash = JSON.parse(json)
        opts = json_hash.except("fields", "files", "position")
        opts[:collection] = Admin::Collection.find(json_hash["collection"])
        self.new(json_hash["fields"].symbolize_keys, json_hash["files"].map(&:deep_symbolize_keys!), opts.symbolize_keys, json_hash["position"], nil)
      end

      def user_key
        @user_key ||= @manifest.package.user.user_key
      end

      def collection
        @collection ||= @manifest.package.collection
      end

      def media_object_fields
        mo_parameters = fields.dup
        #Bibliographic IDs
        bib_id = mo_parameters.delete(:bibliographic_id)
        bib_id_label = mo_parameters.delete(:bibliographic_id_label)
        mo_parameters[:bibliographic_id] = { id: bib_id, source: bib_id_label } if bib_id.present?
        #Other Identifiers
        other_identifier = mo_parameters.delete(:other_identifier)
        other_identifier_type = mo_parameters.delete(:other_identifier_type)
        mo_parameters[:other_identifier] = other_identifier.zip(other_identifier_type).map{|a|{id: a[0], source: a[1]}} if other_identifier.present?
        #Related urls
        related_item_url = mo_parameters.delete(:related_item_url)
        related_item_label = mo_parameters.delete(:related_item_label)
        mo_parameters[:related_item_url] = related_item_url.zip(related_item_label).map{|a|{url: a[0],label: a[1]}} if related_item_url.present?
        #Notes
        # FIXME: lets in empty values!
        note = mo_parameters.delete(:note)
        note_type = mo_parameters.delete(:note_type)
        mo_parameters[:note] = note.zip(note_type).map{|a|{note: a[0],type: a[1]}} if note.present?

        mo_parameters
      end

      def valid?
        # Set errors if does not validate against media_object model
        media_object.valid?
        media_object.errors.messages.each_pair { |field,errs|
          errs.each { |err| @errors.add(field, err) }
        }
        files = @files.select {|file_spec| file_valid?(file_spec)}
        # Ensure files are listed
        @errors.add(:content, "No files listed") if files.empty?
        # Replace collection error if collection not found
        if media_object.collection.nil?
          @errors.messages[:collection] = ["Collection not found: #{@fields[:collection].first}"]
          @errors.messages.delete(:governing_policy)
        end
        @errors.empty?
      end

      def file_valid?(file_spec)
        valid = true
        # Check date_digitized for valid format
        if file_spec[:date_digitized].present?
          begin
            DateTime.parse(file_spec[:date_digitized])
          rescue ArgumentError
            @errors.add(:date_digitized, "Invalid date_digitized: #{file_spec[:date_digitized]}. Recommended format: yyyy-mm-dd.")
            valid = false
          end
        end
        # Check file offsets for valid format
        if file_spec[:offset].present? && !Avalon::Batch::Entry.offset_valid?(file_spec[:offset])
          @errors.add(:offset, "Invalid offset: #{file_spec[:offset]}")
          valid = false
        end
        # Ensure listed files exist
        if FileLocator.new(file_spec[:file]).exist? && self.class.derivativePaths(file_spec[:file]).present?
          @errors.add(:content, "Both original and derivative files found")
          valid = false
        elsif FileLocator.new(file_spec[:file]).exist?
          #Do nothing.
        else
          if self.class.derivativePaths(file_spec[:file]).present? && file_spec[:skip_transcoding]
            #Do nothing.
          elsif self.class.derivativePaths(file_spec[:file]).present? && !file_spec[:skip_transcoding]
            @errors.add(:content, "Derivative files found but skip transcoding not selected")
            valid = false
          else
            @errors.add(:content, "File not found: #{file_spec[:file]}")
            valid = false
          end
        end
        valid
      end

      def self.offset_valid?( offset )
        tokens = offset.split(':')
        return false unless (1...4).include? tokens.size
        seconds = tokens.pop
        return false unless /^\d{1,2}([.]\d*)?$/ =~ seconds
        return false unless seconds.to_f < 60
        unless tokens.empty?
          minutes = tokens.pop
          return false unless /^\d{1,2}$/ =~ minutes
          return false unless minutes.to_i < 60
          unless tokens.empty?
            hours = tokens.pop
            return false unless /^\d{1,}$/ =~ hours
          end
        end
        true
      end

      def self.attach_datastreams_to_master_file( master_file, filename, datastreams )
        structural_file = "#{filename}.structure.xml"
        if FileLocator.new(structural_file).exist?
          master_file.structuralMetadata.content=FileLocator.new(structural_file).reader
          master_file.structuralMetadata.original_name = structural_file
        end
        errors = []
        datastreams.each do |ds|
          next unless ds.present?
          supplemental_file = case ds.keys[0].to_s
                              when /caption.*/
                                process_datastream(ds, 'caption', master_file.id)
                              when /transcript.*/
                                process_datastream(ds, 'transcript', master_file.id)
                              end
          if supplemental_file.nil?
            errors += [ds.values[0].to_s.split('/').last]
            next
          end
          master_file.supplemental_files += [supplemental_file]
        end

        errors
      end

      def process!
        media_object.save

        @files.each do |file_spec|
          master_file = MasterFile.new
          master_file.save(validate: false) #required: need id before setting supplemental files
          # master_file.media_object = media_object
          files = self.class.gatherFiles(file_spec[:file])
          datastreams = gather_datastreams(file_spec).values
          supplemental_file_errors = self.class.attach_datastreams_to_master_file(master_file, file_spec[:file], datastreams)
          @errors.add(:supplemental_files, "Problem saving caption or transcript files: #{supplemental_file_errors}") unless supplemental_file_errors.empty?
          master_file.setContent(files, dropbox_dir: media_object.collection.dropbox_absolute_path)

          # Overwrite files hash with working file paths to pass to matterhorn
          if files.is_a?(Hash) && master_file.working_file_path.present?
            files.each do |quality, file|
              working_path = master_file.working_file_path.find { |path| File.basename(file) == File.basename(path) }
              files[quality] = File.new(working_path)
            end
          end

          master_file.absolute_location = file_spec[:absolute_location] if file_spec[:absolute_location].present?
          master_file.title = file_spec[:label] if file_spec[:label].present?
          master_file.poster_offset = file_spec[:offset] if file_spec[:offset].present?
          master_file.date_digitized = DateTime.parse(file_spec[:date_digitized]).to_time.utc.iso8601 if file_spec[:date_digitized].present?

          #Make sure to set content before setting the workflow
          master_file.set_workflow(file_spec[:skip_transcoding] ? 'skip_transcoding' : nil)
          if master_file.save
            master_file.media_object = media_object
            media_object.save
            master_file.process(files)
          else
            Rails.logger.error "Problem saving MasterFile(#{master_file.id}): #{master_file.errors.full_messages.to_sentence}"
          end
        end
        # context = { media_object: media_object, user: @manifest.package.user.user_key, hidden: opts[:hidden] ? '1' : nil }
        # HYDRANT_STEPS.get_step('access-control').execute context
        media_object.workflow.last_completed_step = 'access-control'

        if opts[:publish]
          media_object.publish!(user_key)
          media_object.workflow.publish
        end

        unless media_object.save
          Rails.logger.error "Problem saving MediaObject: #{media_object}"
        end

        media_object
      end

      def self.gatherFiles(file)
        derivatives = {}
        %w(low medium high).each do |quality|
          derivative = self.derivativePath(file, quality)
          locator = FileLocator.new(derivative)
          derivatives["quality-#{quality}"] = locator.attachment if locator.exist?
        end
        derivatives.empty? ? FileLocator.new(file).attachment : derivatives
      end

      def self.derivativePaths(filename)
        paths = []
        %w(low medium high).each do |quality|
          derivative = self.derivativePath(filename, quality)
          paths << derivative if FileLocator.new(derivative).exist?
        end
        paths
      end

      def self.derivativePath(filename, quality)
        filename.dup.insert(filename.rindex('.'), ".#{quality}")
      end

      def self.caption_language(language)
        begin
          LanguageTerm.find(language.capitalize).code
        rescue LanguageTerm::LookupError
          Settings.caption_default.language
        end
      end
      private_class_method :caption_language

      def self.process_datastream(datastream, type, parent_id)
        file_key, label_key, language_key = ["_file", "_label", "_language"].map { |item| item.prepend(type).to_sym }
        return nil unless datastream[file_key].present? && FileLocator.new(datastream[file_key]).exist?
        
        # Build out file metadata
        filename = datastream[file_key].split('/').last
        label = datastream[label_key].presence || filename
        language = datastream[language_key].present? ? caption_language(datastream[language_key]) : Settings.caption_default.language
        machine_generated = datastream[:machine_generated].present? ? 'machine_generated' : nil
        # Create SupplementalFile
        supplemental_file = SupplementalFile.new(label: label, tags: [type, machine_generated].compact, language: language, parent_id: parent_id)
        supplemental_file.file.attach(io: FileLocator.new(datastream[file_key]).reader, filename: filename)
        supplemental_file.save ? supplemental_file : nil
      end
      private_class_method :process_datastream

      private

        def hidden
          !!opts[:hidden]
        end

        def gather_datastreams(file)
          [] unless file.keys.any? { |k| k.to_s.include?('caption') || k.to_s.include?('transcript') }
          file.select { |f| f.to_s.include?('caption') || f.to_s.include?('transcript') }
        end
    end
  end
end
