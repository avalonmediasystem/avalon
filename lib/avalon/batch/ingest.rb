# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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
    # Handles all activity relating to registering a batch registry and its batch entries
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
        Rails.logger.info "<< Found #{new_packages.count} new packages for collection #{@collection.name} >>" if new_packages.count > 0
        new_packages.each do |package|
          @previous_entries = nil # clear it out in case the last package set it
          @current_package = package
          process_valid_package if valid_package?
        end
      end

      # Given a package, this will validate the structure of the package
      # and send an error email if the package is not valid
      # @return Boolean if the package is valid or not
      def valid_package?
        package_validation
        package_valid = @current_package_errors.empty?
        unless package_valid
          @current_package.manifest.error!
          send_invalid_package_email
        end
        package_valid
      end

      # Given a valid package you have obtained via some means, such as scan_for_packages
      # or passed in via the batch_ingest_job, process it
      def process_valid_package(package: nil)
        # If we're calling this via a side job, we'll be passing in a package here
        # Otherwise this should be set
        # Validate the package if a side package is passed in
        unless package.nil?
          return unless valid_package?
          @current_package = package
        end

        # We have a valid batch so we can go ahead and delete the manifest file
        @current_package.manifest.delete

        br = register_batch unless replay?
        br = register_replay if replay?
        @current_batch_registry = br.reload
        @previous_entries = fetch_previous_entries if replay?
        register_entries
        # Queue all the entries
        BatchEntries.where(batch_registries_id: @current_batch_registry.id, complete: false, error: false).map(&:queue)

        # Now that everything is registered, unlock the batch entry
        # TODO: Move these two lines to the model
        @current_batch_registry.locked = false
        if @current_batch_registry.save
          # Send email about successful registration
          BatchRegistriesMailer.batch_ingest_validation_success(@current_package).deliver_now if @current_batch_registry.persisted?
        else
          Rails.logger.error "Persisting BatchRegistry failed for package #{@current_package.title}"
        end
      end

      # Register the individual rows on a spreadsheet for a valid package
      def register_entries
        position = 1 # acts_as_list starts at 1, not 0
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
        previous_entry = @previous_entries[position - 1]
        # Case 0, determine if we even have an updated at all
        # If the payload is the same it means no change and complete true means the migration ran
        return nil if previous_entry.payload == entry.to_json && previous_entry.complete

        # Case 1, if there is a payload change and the item never completed, reset to pending
        # Also reset to pending if there is an error
        reset_to_pending(previous_entry, entry) if !previous_entry.complete || previous_entry.error

        # Case 2, if there is a published media object we cannot replay
        unless previous_entry.media_object_pid.nil?
          mo = MediaObject.find(previous_entry.media_object_pid)
          unless mo.nil? # meaning the media_object has been deleted since last time this ran
            if mo.published?
              published_error(previous_entry)
              return nil # no further action, break out
            else
              reset_to_pending(previous_entry, entry)
            end
          end
        end
      end

      # Reset a row to pending status when replaying
      # @param [Avalon::Batch::Entry] the entry to register
      # @param [BatchEntries] the previous batch entry to reset_to_pending
      # @return [BatchEntries] the reset entrt
      def reset_to_pending(previous_entry, entry)
        previous_entry.payload = entry.to_json
        previous_entry.error = false
        previous_entry.error_message = false
        previous_entry.complete = false
        previous_entry.current_status = 'registered'
        previous_entry.save
        previous_entry
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
      # @return [BatchEntries] the ActiveRecord entry for the new entry
      def new_entry(entry)
        BatchEntries.create(
          batch_registries_id: @current_batch_registry.id,
          payload: entry.to_json,
          complete: false,
          error: false,
          current_status: 'registered'
        )
      end

      # When replaying a manifest, fetch the previous entries for updating
      # @return BatchEntries::ActiveRecord_Relation all of the entries for the current manifest
      def fetch_previous_entries
        batch_id = BatchRegistries.where(replay_name: @current_package.title).first.id
        BatchEntries.where(batch_registries_id: batch_id)
      end

      # Uses the filename to determine if a batch is a replay using the filename
      # @return Boolean whether or not the file is a replay
      def replay?
        BatchRegistries.exists?(replay_name: @current_package.title)
      end

      # Registers a new batch manifest and sets it to locked, locked manifests are not proccessed
      # This is done so processing does not begin while individual lines are registered
      # @param [Boolean] whether or not the manifest is valid, defaults to true
      def register_batch(valid: true)
        # TODO: Save dir
        br = BatchRegistries.new(
          user_id: @current_package.user.id,
          dir: @current_package.dir,
          file_name: @current_package.title,
          collection: @current_package.collection.id,
          error: !valid,
          complete: false,
          locked: true
        )
        br.save
        br
      end

      # Registers a replay batch manifest and sets it to locked, locked manifests are not processed_email_sent
      # This is done so processing does not begin while individual lines are registered
      # @raise ArgumentError raised if the collection ids do not match
      def register_replay(valid: true)
        # TODO: Save dir
        br = BatchRegistries.where(replay_name: @current_package.title).first
        raise ArgumentError, "Collections cannot change on replay, replay using #{@current_package.title} failed" if br.collection != @current_package.collection.id
        br.user_id = @current_package.user.id
        br.dir = @current_package.dir
        br.file_name = @current_package.title
        br.error = !valid
        br.complete = false
        br.processed_email_sent = false
        br.completed_email_sent = false
        br.error_email_sent = false
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
        raise '@current_package is not set' if @current_package.nil?
        @current_package_errors = []
        @current_package_errors += user_checks
        @current_package_errors += file_checks
        @current_package_errors
      end

      # Checks for a user and validates user permissions to upload to the target collection
      # requires that @current_package and @collection be set
      # @return Array <String> an array of errors related to the user
      def user_checks
        current_user = @current_package.user
        current_ability = Ability.new(current_user)
        errors = []
        errors = check_current_user(current_user, errors)
        return errors unless errors.empty?
        errors << "User does not exist in the system: #{@current_package.manifest.email}." if current_user.nil?
        errors << "User #{current_user.user_key} does not have permission to add items to collection: #{collection.name}." unless current_ability.can?(:read, collection)
        errors
      end

      # Determines if we have a valid ActiveRecord relation for current_user
      # @param  [User] the user
      # @param [Array <String>] an array to append any errors to
      # @return [Array <String>] the array of errors with any new errors appended
      def check_current_user(current_user, errors)
        errors << "For #{@current_package.title}, a valid user cannot be found." if current_user.nil? || current_user.user_key.nil?
        errors
      end

      # Checks the manifest file in the package for validity
      # Ensures there are entries in the file
      # @return Array <String> an array of errors related to the user
      def file_checks
        errors = []
        errors << 'There are no entries in the manifest file.' if @current_package.manifest.count == 0
        errors
      end

      def send_invalid_package_email
        Rails.logger.warn "Could not register package #{@current_package.title} for Collection #{@collection.id}, sending email."
        BatchRegistriesMailer.batch_ingest_validation_error(@current_package, @current_package_errors).deliver_now
      end
    end
  end
end
