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

require 'iconv'
require 'avalon/workflow/workflow_controller_behavior'
require 'avalon/controller/controller_behavior'
require 'avalon/dropbox'

module Avalon
  module Batch
    class Ingest

      include Avalon::Controller::ControllerBehavior

      attr_reader :collection

      def initialize(collection)
        @collection = collection
      end

      def initialize_media_object_from_package( entry, user )
        fields = entry.fields.dup
        media_object = MediaObject.new(avalon_uploader: user)
        media_object.workflow.origin = 'batch'
        media_object.collection = collection
        media_object.update_datastream(:descMetadata, fields)
        media_object
      end
      
      def offset_valid?( offset )
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

      def ingest

        # Scans dropbox for new batch packages
        new_packages = collection.dropbox.find_new_packages
        logger.info "<< Found #{new_packages.count} new packages for collection #{collection.name} >>"

        if new_packages.length > 0
          # Extracts package and process
          new_packages.each_with_index do |package, index|
            media_objects = []
            base_errors = []
            email_address = package.manifest.email || Avalon::Configuration.lookup('email.notification')
            current_user = User.where(username: email_address).first || User.where(email: email_address).first
            current_ability = Ability.new(current_user)
            if current_user.nil?
              base_errors << "User does not exist in the system: #{email_address}."
            elsif !collection
              base_errors << "There is not a collection in the system with the name: #{collection.name}."
            elsif !current_ability.can?(:read, collection)
              base_errors << "User #{email_address} does not have permission to add items to collection: #{collection.name}."
            end
            if base_errors.empty?
              package.validate do |entry|
                media_object = initialize_media_object_from_package( entry, current_user.user_key )
                media_object.valid?
                if entry.fields[:collection].present? && entry.fields[:collection].first != collection.name
                  entry.errors.add(:collection, "The listed collection (#{entry.fields[:collection].first}) does not match the ingest folder name (#{collection.name}).")
                end
                entry.files.each {|file_spec| entry.errors.add(:offset, "Invalid offset: #{file_spec[:offset]}") if file_spec[:offset].present? && !offset_valid?(file_spec[:offset])}
                files = entry.files.collect { |f| File.join( package.dir, f[:file]) }
                entry.errors.add(:content, "No files listed") if files.empty?
                files.each_with_index do |f,i| 
                  media_object.errors.add(:content, "File not found: #{entry.files[i]}") unless File.file?(f)
                end
                media_object
              end
            end
            if base_errors.empty? && package.valid?

              package.process do |fields, files, opts, entry|
                media_object = initialize_media_object_from_package( entry, current_user.user_key )
                media_object.save( validate: false)

                files.each do |file_spec|
                  mf = MasterFile.new
                  mf.save( validate: false )
                  mf.mediaobject = media_object
                  mf.setContent(File.open(file_spec[:file], 'rb'))
                  mf.absolute_location = file_spec[:absolute_location] if file_spec[:absolute_location].present?
                  mf.set_workflow(file_spec[:skip_transcoding] ? 'skip_transcoding' : false)
                  mf.label = file_spec[:label] if file_spec[:label].present?
                  mf.poster_offset = file_spec[:offset] if file_spec[:offset].present?
                  if mf.save
                    media_object.save(validate: false)
                    mf.process
                  end
                end

                context = {media_object: { pid: media_object.pid, access: 'private' }, mediaobject: media_object, user: current_user.user_key, hidden: opts[:hidden] ? '1' : nil }
                context = HYDRANT_STEPS.get_step('access-control').execute context

                media_object.workflow.last_completed_step = 'access-control'

                if opts[:publish]
                  media_object.publish!(current_user.user_key)
                  media_object.workflow.publish
                end

                if media_object.save
                  logger.debug "Done processing package #{index}"
                else
                  logger.error "Problem saving MediaObject: #{media_object}"
                end

                media_objects << media_object
              end
              # send email confirming kickoff of batch
              IngestBatchMailer.batch_ingest_validation_success( package ).deliver
            else
              package.manifest.error!
              IngestBatchMailer.batch_ingest_validation_error( package, base_errors ).deliver
            end

            # Create an ingest batch object for 
            # all of the media objects associated with this 
            # particular package
            IngestBatch.create( 
              media_object_ids: media_objects.map(&:id), 
              name:  package.manifest.name,
              email: current_user.email,
            ) if media_objects.length > 0

          end
        end
      end
    end
  end
end
