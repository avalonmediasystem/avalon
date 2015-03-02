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
        # Extract package and process
        new_packages.each do |package|
          begin
            ingest_batch = ingest_package(package)
          rescue Exception => ex
            begin
              package.manifest.error!
            ensure
              IngestBatchMailer.batch_ingest_validation_error( package, ["#{ex.class.name}: #{ex.message}"] ).deliver
            end
          end
        end
      end

      def ingest_package(package)
        base_errors = []
        current_user = package.user
        current_ability = Ability.new(current_user)
        # Validate base package attributes: user, collection, and authorization
        if current_user.nil?
          base_errors << "User does not exist in the system: #{package.manifest.email}."
        elsif !current_ability.can?(:read, collection)
          base_errors << "User #{current_user.user_key} does not have permission to add items to collection: #{collection.name}."
        elsif package.manifest.count==0
          base_errors << "There are no entries in the manifest file."
        end
        package.entries.each do |entry| 
          if entry.fields.has_key?(:collection) && entry.fields[:collection].first!=collection.name
            entry.errors.add(:collection, "Collection '#{entry.fields[:collection].first}' does not match ingest folder '#{collection.name}'") 
          end
        end
        if !base_errors.empty? || !package.valid?
          package.manifest.error!
          IngestBatchMailer.batch_ingest_validation_error( package, base_errors ).deliver
          return nil
        end
        media_objects = package.process!
        # send email confirming kickoff of batch
        IngestBatchMailer.batch_ingest_validation_success( package ).deliver
        # Create an ingest batch object for all of the media objects associated with this particular package
        IngestBatch.create( media_object_ids: media_objects.map(&:id), name: package.manifest.name, email: current_user.email )
      end

    end
  end
end
