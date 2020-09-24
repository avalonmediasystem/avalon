# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

module IngestBatchStatusEmailJobs
  # @since 6.3.0
  # Scans all BatchRegistries to look for registries where all entries are complete or errored
  # Sends an email to the user to alert them to this fact
  class IngestFinished < ActiveJob::Base
    queue_as :ingest_finished_job
    unique :until_executed, on_conflict: :log

    def perform
      # Get all unlocked items that don't have an email sent for them and see if an email can be sent
      BatchRegistries.where(completed_email_sent: false, error_email_sent: false, locked: false).each do |br|
        # Get the entries for the batch and see if they all complete
        complete = true
        errors = false
        br.batch_entries.each do |entry|
          complete = false unless entry.complete || entry.error
          errors = true if entry.error
        end

        next unless complete

        BatchRegistriesMailer.batch_registration_finished_mailer(br).deliver_now
        if errors
          br.error_email_sent = true
          br.error = true
        else
          br.completed_email_sent = true
          br.complete = true
        end
        br.save
      end

      # Done encoding? (either successfully or with error)
      BatchRegistries.where(processed_email_sent: false,
                            error: false,
                            complete: true).each do |br|
        if br.encoding_finished?
          BatchRegistriesMailer.batch_encoding_finished(br).deliver_now
          br.processed_email_sent = true
          if br.encoding_error?
            br.error = true
          end
          br.save
        end
      end

    end
  end

  # @since 6.3.0
  # Scans all batch registries that are not completed and determines if that have been
  # sitting for an inordinate amount of time, alerts the admin user if this is the case
  class StalledJob < ActiveJob::Base
    queue_as :ingest_status_job
    def perform
      stall_time = 4.days
      # Get every batch registry not marked as complete
      BatchRegistries.where(completed_email_sent: false, error_email_sent: false).each do |br|
        batch_stalled = false
        batch_stalled = true if br.locked && Time.now.utc - br.updated_at > stall_time
        unless batch_stalled
          BatchEntries.where(batch_registries_id: br.id, error: false, complete: false).each do |be|
            batch_stalled = true if Time.now.utc - be.updated_at > stall_time
            break if batch_stalled
          end
        end
        BatchRegistriesMailer.batch_registration_stalled_mailer(br) if batch_stalled
      end
    end
  end
end
