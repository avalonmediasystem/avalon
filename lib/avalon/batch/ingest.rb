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

require 'iconv'
require 'avalon/workflow/workflow_controller_behavior'
require 'avalon/controller/controller_behavior'
require 'avalon/dropbox'

module Avalon
  module Batch
    class Ingest

      attr_reader :collection

      def initialize(collection)
        @collection = collection
      end

      # Scans the dropbox for new batch packages and registers them
      #
      def scan_for_packages
        # Scan the dropbox
        new_packages = collection.dropbox.find_new_packages
        logger.info "<< Found #{new_packages.count} new packages for collection #{@collection.name} >>" if new_packages.count > 0
        # For Each
        new_package.each do |package|
          @current_package = package
          package_validation
          # Determine if package is valid
          package_valid = @current_package_errors.empty?
          # TODO: Register failed package and send the email
          next unless package_valid
          replay = BatchRegistries.exists?(replay_name: @package.title)
          BatchRegistries.register_batch(@current_package) unless replay
          BatchRegistries.register_replay(@current_package) if replay
        end
        # Return something about the new batches
      end

      def register_batch(valid: true)
        obj = {
          email: @current_package.user.email,
          file_name: @current_package.title,
          replay_name: "#{SecureRandom.uuid}-#{@current_package.title}",
          collection: @current_package.collection.id,
          valid_manifest: valid,
          completed: false,
          email_sent: false,
          locked: true
        }
        BatchRegistries.new(obj)
      end


      # Determines if @current_package is valid
      # Checks for user permissions and validity of the package file
      # Stores errors in @current_package_errors
      # @raise RuntimeError raised when @current_package is not sent
      # @return Array <String> an array of the errors
      def package_validation
        fail RuntimeError, '@current_package is not set' unless @current_package.nil?
        @current_package_errors = []
        @current_package_errors << user_checks
        @current_package_errors << file_checks
        @current_package_errors
      end

      # Checks for a user and validates user permissions to upload to the target collection
      # requires that @current_package and @collection be set
      # @return Array <String> an array of errors related to the user
      def user_checks
          current_user = @current_package.user
          current_ability = Ability.new(current_user)
          errors = []
          errors << "User does not exist in the system: #{package.manifest.email}." if current_user.nil?
          errors << "User #{current_user.user_key} does not have permission to add items to collection: #{collection.name}." if !current_ability.can?(:read, collection)
          errors
      end

      # Checks the manifest file in the package for validity
      # Ensures there are entries in the file
      # @return Array <String> an array of errors related to the user
      def files_checks
        errors = []
        errors << "There are no entries in the manifest file." if @current_package.manifest.count==0
        errors
      end

      def ingest
        # Scans dropbox for new batch packages
        new_packages = collection.dropbox.find_new_packages
        logger.info "<< Found #{new_packages.count} new packages for collection #{collection.name} >>" if new_packages.count > 0
        # Extract package and process
        new_packages.each do |package|
          begin
            ingest_batch = ingest_package(package)
          rescue Exception => ex
            begin
              package.manifest.error!
            ensure
              IngestBatchMailer.batch_ingest_validation_error( package, ["#{ex.class.name}: #{ex.message}"] ).deliver_now
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
          IngestBatchMailer.batch_ingest_validation_error( package, base_errors ).deliver_now
          return nil
        end
        media_objects = package.process!
        # send email confirming kickoff of batch
        IngestBatchMailer.batch_ingest_validation_success( package ).deliver_now
        # Create an ingest batch object for all of the media objects associated with this particular package
        IngestBatch.create( media_object_ids: media_objects.map(&:id), name: package.manifest.name, email: current_user.email )
      end

    end
  end
end
