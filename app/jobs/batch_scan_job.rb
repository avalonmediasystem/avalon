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

# frozen_string_literal: true
class BatchScanJob < ActiveJob::Base
  queue_as :batch_ingest
  unique :until_executed, on_conflict: :log

  # Registers a batch ingest manifest that has been uploaded to an S3 bucket
  # replaces `def scan_for_packages` since S3 can trigger a lambda to enqueue
  # this job, removing the need to scan ever X minutes
  # @param [String] the path to the manifest in the form of S3://...
  def perform
    Rails.logger.info "<< Scanning for new batch packages in existing collections >>"
    Admin::Collection.all.each do |collection|
      Avalon::Batch::Ingest.new(collection).scan_for_packages
    end
  end
end
