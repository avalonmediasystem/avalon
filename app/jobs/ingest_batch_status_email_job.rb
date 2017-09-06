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

# @since 6.2.0
# Scans all BatchRegistries where and email has not been sent and sends
class IngestBatchStatusEmail < ActiveJob::Base
  queue_as :ingest_status_mailer
  def perform
    # Get all unlocked items that don't have an email sent for them and see if an email can be sent
    BatchRegistries.where(completed_email_sent: false, error_email_sent: false, locked: false).each do |br|
      # Get the entries for the batch and see if they all complete
      status = { complete: true, errors: false }
      BatchEntries.where(batch_registries_id: br.id).each do |entry|
        status[complete] = false unless entry.complete || entry.error
        status[errors] = true if entry.error
      end

      next unless status[complete]
        unless status[errors]
          # TODO Send complete email
          entry.completed_email_sent = true
          entry.complete = true
        end
        if status [errors]
          # TODO Send error email
          entry.error_email_sent = true
          entry.error = true
        end
        entry.save
      end






    end
  end
end
