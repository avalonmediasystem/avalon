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

    include Avalon::Controller::ControllerBehavior

    def self.initialize_media_object_from_package( entry, email_address)
      fields = entry.fields.dup
      media_object = MediaObject.new
      media_object.workflow.origin = 'batch'
      media_object.collection = Avalon::Batch.find_collection_from_fields( fields )
      media_object.update_datastream(:descMetadata, fields)
      media_object
    end
    
    def self.find_collection_from_fields( fields )
      collection_name = fields[:collection]
      return nil unless collection_name.present?
      Admin::Collection.where( name: collection_name ).first
    end


    def self.ingest
      # Scans dropbox for new batch packages
      logger.debug "============================================"
      logger.debug "<< Starts scanning for new batch packages >>"
      
      new_packages = Avalon::DropboxService.find_new_packages
      logger.debug "<< Found #{new_packages.count} new packages >>"


      if new_packages.length > 0
        # Extracts package and process
        new_packages.each_with_index do |package, index|
          logger.debug "<< Processing package #{index} >>"

          media_objects = []
          base_errors = []
          email_address = package.manifest.email || Avalon::Configuration['email']['notification']
          current_user = User.where(email: email_address).first
          ability = Ability.new current_user
          ability.instance_variable_set("@user", current_user)
          package.validate do |entry|
            media_object = Avalon::Batch.initialize_media_object_from_package( entry, email_address )
            if media_object.collection && ! ability.can?(:read, media_object.collection)
              base_errors << "You do not have permission to add items to collection: #{media_object.collection.name}."
            elsif ! media_object.collection && entry.fields[:collection].present?
              base_errors << "There is not a collection in the system with the name: #{entry.fields[:collection].first}."
            end
            media_object
          end

          if package.valid? && base_errors.empty?

            package.process do |fields, files, opts, entry|
              media_object = Avalon::Batch.initialize_media_object_from_package( entry, email_address )
              media_object.save( validate: false)

              files.each do |file_path|
                mf = MasterFile.create
                mf.mediaobject = media_object
                mf.setContent(File.open(file_path, 'rb'))
                if mf.save
                  media_object.save(validate: false)
                  mf.process
                end
              end

              context = {media_object: { pid: media_object.pid, hidden: opts[:hidden] ? '1' : nil, access: 'private' }, mediaobject: media_object, user: email_address }
              context = HYDRANT_STEPS.get_step('access-control').execute context

              media_object.workflow.last_completed_step = 'access-control'

              if opts[:publish]
                media_object.publish!(email_address)
                media_object.workflow.publish
              end

              if media_object.save
                logger.debug "Done processing package #{index}"
              else
                logger.debug "Problem saving MediaObject: #{media_object}"
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
            email: email_address,
          ) if media_objects.length > 0

        end
      end
    end
  end
end
