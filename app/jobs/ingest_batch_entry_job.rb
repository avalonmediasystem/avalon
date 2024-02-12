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

class IngestBatchEntryJob < ActiveJob::Base
  queue_as :ingest

  # ActiveJob will serialize/deserialize the batch_entry automatically using GlobalIDs
  def perform(batch_entry)
    # Validation checking that it is okay to ingest this batch entry
    if batch_entry.media_object_pid.present? && MediaObject.exists?(batch_entry.media_object_pid)
      mo = MediaObject.find(batch_entry.media_object_pid)
      if mo.published?
        published_error(batch_entry)
        return
      end
    end


    entry = Avalon::Batch::Entry.from_json(batch_entry.payload)
    if entry.valid?
      # Set to process status on the BatchEntries
      update_status(batch_entry, "Processing")
      # Start processing
      entry.process!
      # Success handling
      process_success(batch_entry, entry)
    else
      # Report error
      invalid_error(batch_entry, entry)
    end
    # TODO any post processing to update status?

  rescue StandardError => e
    process_error(batch_entry, e)
  end

  private
    # Set an error when a mediaobject has already been published and
    # @param [BatchEntries] the entry to update
    def published_error(previous_entry)
      previous_entry.error = true
      previous_entry.complete = false
      previous_entry.current_status = 'Update Rejected'
      previous_entry.error_message = 'Cannot update this item, it has already been published.'
      previous_entry.save
    end

    # @param [BatchEntries] the entry to update
    # @param [String] status to update the batch entry to
    def update_status(batch_entry, status)
      batch_entry.current_status = status
      batch_entry.save!
    end

    # @param [BatchEntries] the entry to update
    # @param [Avalon::Batch::Entry] the entry to update
    def process_success(batch_entry, entry)
      old_media_object_id = batch_entry.media_object_pid
      batch_entry.media_object_pid = entry.media_object.id
      batch_entry.complete = true
      batch_entry.save!
      # Delete pre-existing media object
      MediaObject.find(old_media_object_id).destroy if old_media_object_id.present? && MediaObject.exists?(old_media_object_id)
    end

    # Set an error when the entry is invalid
    # @param [BatchEntries] the entry to update
    # @param [Avalon::Batch::Entry] the entry to update
    def invalid_error(batch_entry, entry)
      batch_entry.error = true
      batch_entry.complete = false
      batch_entry.current_status = 'Invalid Entry'
      batch_entry.error_message = entry.errors.full_messages.to_sentence
      batch_entry.save
    end

    # Set an error when an error occurs during processing
    # @param [BatchEntries] the entry to update
    # @param [RuntimeError] the error raised
    def process_error(batch_entry, error)
      batch_entry.error = true
      batch_entry.complete = false
      batch_entry.current_status = 'Processing Error'
      batch_entry.error_message = error.message
      batch_entry.save
    end
end
