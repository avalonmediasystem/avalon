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
          @previous_entries = nil #clear it out in case the last package set it
          @current_package = package
          package_validation
          package_valid = @current_package_errors.empty?
          send_invalid_package_email unless package_valid
          next unless package_valid
          br = BatchRegistries.register_batch unless replay?
          br = BatchRegistries.register_replay if replay?
          @current_batch_registry = br.reload
          @previous_entries = fetch_previous_entries if replay?
          register_entries
          # Kick off a job for every entry in pending
          # Unlock the table
        end
        # Return something about the new batches

      end

      def register_entries
        position = 1 #acts_as_list starts at 1, not 0
        @current_package.entries.each do |entry|
          new_entry(entry) if @previous_entries.nil?
          replay_entry(entry, position) unless @previous_entries.nil?
          position += 1
        end
      end

      # Handles the issues involved in registering a replay entry
      # Assumes @previous_entries is populated
      # @param [Avalon::Batch::Entry] the entry to register
      # @param [Integer] the position on the spreadsheet, starting from 1, not 0, since acts_as_list starts at 1
      def replay_entry(entry, position)
        previous_entry = @previous_entries[position]
        # Case 0, determine if we even have an updated at all
        # If the payload is the same it means no change and complete true means the migration ran
        return nil if previous_entry.payload == entry.fields.to_json && complete

        # Case 1, if there is a payload change and the item never completed, reset to pending
        reset_to_pending(previous_entry, entry)


        # Case 1, if there is a published media object we cannot replay
        unless previous_entry.media_object_pid.nil?
          mo = MediaObject.find(previous_entry.media_object_pid)
          unless mo.nil? #meaning the media_object has been deleted since last time this ran
            if mo.published?
              published_error(previous_entry)
              return nil #no further action, break out
            end
          end
        end

        # Case 2


      end

      #
      def reset_to_pending(previous_entry, entry)
      end

      # Set an error when a mediaobject has already been published and
      # @param [BatchEntries] the entry to update
      def published_error(previous_entry)
        previous_entry.error = true
        previous_entry.complete = false
        previous_entry.current_status = 'Update Rejected'
        previous_entry.error_message = 'Cannot update this item, it has already been published.'
        previous_entry.save
      end

      # Registries a new entry for a manifest that has never been run before
      # Assumes @current_batch_registry is set
      # @param [Avalon::Batch::Entry] entry the entry to register
      def new_entry(entry)
        be = BatchEntries.new(
                              batch_registries_id: @current_batch_registry.id,
                              payload: entry.fields.to_json,
                              complete: false,
                              error: false,
                              current_status: 'registered'
        )
        be.save
        be
      end

      # When replaying a manifest, fetch the previous entries for updating
      # @return BatchEntries::ActiveRecord_Relation all of the entries for the current manifest
      def fetch_previous_entries
        batch_id = BatchRegistries.where(replay_name: @current_package.file_name).first.id
        BatchEntries.where(batch_registries_id: batch_id)
      end



      # Uses the filename to determine if a batch is a replay using the filename
      # @return Boolean whether or not the file is a replay
      def replay?
        replay = BatchRegistries.exists?(replay_name: @current_package.title)
      end

      # Registers a new batch manifest and sets it to locked, locked manifests are not proccessed
      # This is done so processing does not begin while individual lines are registered
      # @param [Boolean] whether or not the manifest is valid, defaults to true
      def register_batch(valid: true)
        #TODO: Save dir
        br = BatchRegistries.new(
                        user_id: @current_package.user.id,
                        file_name: @current_package.title,
                        collection: @current_package.collection.id,
                        valid_manifest: valid,
                        completed: false,
                        email_sent: false,
                        locked: true
        )
        br.save
        br
      end

      # Registers a replay batch manifest and sets it to locked, locked manifests are not processed_email_sent
      # This is done so processing does not begin while individual lines are registered
      # @raise ArgumentError raised if the collection ids do not match
      def register_replay(valid: true)
        #TODO: Save dir
        br = BatchRegistries.where(replay_name: @current_package.title).first
        fail ArgumentError, "Collections cannot change on replay, replay using #{@current_package.title} failed" if br.collection != @current_package.collection.id
        br.user_id = @current_package.user.id
        br.file_name = @current_package.title
        br.valid_manifest = valid,
        br.completed = false,
        br.email_sent = false,
        br.locked = true
        br.save
        br
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

      def send_invalid_package_email
        #TODO: Write me!
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
