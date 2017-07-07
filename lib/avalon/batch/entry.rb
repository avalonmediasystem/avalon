# Copyright 2011-2017, The Trustees of Indiana University and Northwestern
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
    	  @fields = fields
    	  @files  = files
    	  @opts   = opts
    	  @row    = row
    	  @manifest = manifest
    	  @errors = ActiveModel::Errors.new(self)
    	  @files.each { |file| file[:file] = File.join(@manifest.package.dir, file[:file]) }
      end

        def media_object
          @media_object ||= MediaObject.new(avalon_uploader: @manifest.package.user.user_key,
                                            collection: @manifest.package.collection).tap do |mo|
            mo.workflow.origin = 'batch'
            mo.workflow.last_completed_step = HYDRANT_STEPS.last.step
            if Avalon::BibRetriever.configured? and fields[:bibliographic_id].present?
              begin
                mo.descMetadata.populate_from_catalog!(fields[:bibliographic_id].first, Array(fields[:bibliographic_id_label]).first)
              rescue Exception => e
                @errors.add(:bibliographic_id, e.message)
              end
            else
              begin
                mo.update_attributes(media_object_fields)
              rescue ActiveFedora::UnknownAttributeError => e
                @errors.add(e.attribute.to_sym, e.message)
              end
            end
          end
          @media_object
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
          if File.file?(file_spec[:file]) && self.class.derivativePaths(file_spec[:file]).present?
            @errors.add(:content, "Both original and derivative files found")
            valid = false
          elsif File.file?(file_spec[:file])
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

      def self.attach_datastreams_to_master_file( master_file, filename )
          structural_file = "#{filename}.structure.xml"
          if File.exists? structural_file
            master_file.structuralMetadata.content=File.open(structural_file)
            master_file.structuralMetadata.original_name = structural_file
          end
          captions_file = "#{filename}.vtt"
          if File.exists? captions_file
            master_file.captions.content=File.open(captions_file)
            master_file.captions.mime_type='text/vtt'
            master_file.captions.original_name = captions_file
          end
      end

      def process!
        media_object.save

        @files.each do |file_spec|
          master_file = MasterFile.new
          # master_file.save(validate: false) #required: need id before setting media_object
          # master_file.media_object = media_object
          files = self.class.gatherFiles(file_spec[:file])
          self.class.attach_datastreams_to_master_file(master_file, file_spec[:file])
          master_file.setContent(files)
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
            logger.error "Problem saving MasterFile(#{master_file.id}): #{master_file.errors.full_messages.to_sentence}"
          end
        end
        context = { media_object: media_object, user: @manifest.package.user.user_key, hidden: opts[:hidden] ? '1' : nil }
        HYDRANT_STEPS.get_step('access-control').execute context
        media_object.workflow.last_completed_step = 'access-control'

        if opts[:publish]
          media_object.publish!(@manifest.package.user.user_key)
          media_object.workflow.publish
        end

        unless media_object.save
          logger.error "Problem saving MediaObject: #{media_object}"
        end

        media_object
      end

      def self.gatherFiles(file)
        derivatives = {}
        %w(low medium high).each do |quality|
          derivative = self.derivativePath(file, quality)
          derivatives["quality-#{quality}"] = File.new(derivative) if File.file? derivative
        end
        derivatives.empty? ? File.new(file) : derivatives
      end

      def self.derivativePaths(filename)
        paths = []
        %w(low medium high).each do |quality|
          derivative = self.derivativePath(filename, quality)
          paths << derivative if File.file? derivative
        end
        paths
      end

      def self.derivativePath(filename, quality)
        filename.dup.insert(filename.rindex('.'), ".#{quality}")
      end
    end
  end
end
