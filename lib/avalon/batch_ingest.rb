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
      
      def ingest

        # Scans dropbox for new batch packages
        new_packages = collection.dropbox.find_new_packages
        logger.info "<< Found #{new_packages.count} new packages for collection #{collection.name} >>"

        if new_packages.length > 0
          # Extract package and process
          new_packages.each_with_index do |package, index|
            media_objects = []
            base_errors = []
            email_address = package.manifest.email || Avalon::Configuration.lookup('email.notification')
            current_user = User.where(username: email_address).first || User.where(email: email_address).first
            current_ability = Ability.new(current_user)
            # Validate base package attributes: user, collection, and authorization
            if current_user.nil?
              base_errors << "User does not exist in the system: #{email_address}."
            elsif !collection
              base_errors << "There is not a collection in the system with the name: #{collection.name}."
            elsif !current_ability.can?(:read, collection)
              base_errors << "User #{email_address} does not have permission to add items to collection: #{collection.name}."
            end
            if base_errors.empty? && package.valid?(current_user,collection)
              media_objects = package.process(current_user, collection)
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
