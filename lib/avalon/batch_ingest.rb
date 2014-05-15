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
      
      def find_collection_from_fields( fields )
        collection_name = fields[:collection]
        return nil unless collection_name.present?
        Admin::Collection.where( name: collection_name ).first
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
        return unless new_packages.length > 0
        
        logger.info "<< Found #{new_packages.count} new packages for collection #{collection.name} >>"

        new_packages.each do |package|
          begin
            process_package(package)
          rescue Exception => e
            message = "#{e.inspect}" + e.backtrace.join("/n")
            package.manifest.error!(message)
            IngestBatchMailer.batch_ingest_validation_error(package, [message]).deliver
          end
        end
      end
      
      def process_package ( package )
        media_objects = []
        current_user = package_user( package )
        if validate_package(package, current_user)
          package.process do |fields, files, opts, entry|
            media_object = initialize_media_object_from_package( entry, current_user.user_key )
            media_object.save( validate: false)
            # Create masterfile for each file
            files.each {|file_spec| create_masterfile(file_spec, media_object)}
            context = {media_object: { pid: media_object.pid, access: 'private' }, mediaobject: media_object, user: current_user.user_key, hidden: opts[:hidden] ? '1' : nil }
            context = HYDRANT_STEPS.get_step('access-control').execute context

            media_object.workflow.last_completed_step = 'access-control'

            if opts[:publish]
              media_object.publish!(current_user.user_key)
              media_object.workflow.publish
            end

            if media_object.save
              logger.debug "Done processing package #{package.manifest.file}"
            else
              logger.error "Problem saving MediaObject: #{media_object}"
            end
            media_objects << media_object
          end
          # send email confirming kickoff of batch
          IngestBatchMailer.batch_ingest_validation_success( package ).deliver
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
 
      def validate_package ( package, current_user )
        base_errors = []
        if current_user.nil?
          base_errors << "User does not exist in the system: #{package_email(package)}." 
        else
          package.validate do |entry|
            mo = validate_entry!(entry, current_user)
            base_errors += entry.errors.messages.to_a
            mo
          end 
        end
        if base_errors.count > 0
          package.manifest.error!
          IngestBatchMailer.batch_ingest_validation_error( package, base_errors ).deliver
          return false
        end
        package.valid?
      end

      def validate_entry! ( entry, current_user )
        current_ability = Ability.new(current_user)
        media_object = initialize_media_object_from_package(entry, current_user.user_key )
        if media_object.collection && ! current_ability.can?(:read, media_object.collection)
          entry.errors.add(:collection, "You do not have permission to add items to collection: #{collection.name}.")
        elsif ! media_object.collection && entry.fields[:collection].present?
          entry.errors.add(:collection, "There is not a collection in the system with the name: #{entry.fields[:collection].first}.")
        end
        entry.files.each {|file_spec| entry.errors.add(:offset, "Invalid offset: #{file_spec[:offset]}") if file_spec[:offset].present? && !offset_valid?(file_spec[:offset])}
        media_object
      end

      def package_user ( package )
        User.where(username: package_email(package)).first || User.where(email: package_email(package)).first
      end
  
      def package_email ( package )
        package.manifest.email || Avalon::Configuration.lookup('email.notification')
      end


      def create_masterfile ( file_spec, media_object )
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

    end
  end
end
