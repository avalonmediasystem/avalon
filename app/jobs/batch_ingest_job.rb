# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

# This job is primarily intended for use within an AWS or similar environment
# When a new spreadsheet is uploaded S3 will trigger an AWS Lambda, which in
# turn queues the job below.
#
# Note that is is not required for AWS, but is cleaner.  The other option is
# to take the `avalon:batch:ingest` from `config/schedule.rb` and alter it to
# scan a selected S3 Bucket (or buckets) and then add it to `cron.yaml`
#
#
# Secondly please review:
# https://github.com/nulib/avalon/wiki/Throttling-Batch-Ingest-on-AWS
# for performance related issues that may arise depending on your AWS config

class BatchIngestJob < ActiveJob::Base
  queue_as :batch_ingest
  # Registers a batch ingest manifest that has been uploaded to an S3 bucket
  # replaces `def scan_for_packages` since S3 can trigger a lambda to enqueue
  # this job, removing the need to scan ever X minutes
  # @param [String] the path to the manifest in the form of S3://...
  def perform(filename)
    return unless Avalon::Batch::Manifest.is_spreadsheet?(filename) && Avalon::Batch::S3Manifest.status(filename).blank?

    uri = Addressable::URI.parse(filename)
    dropbox_directory = uri.route_from(Addressable::URI.parse(Settings.dropbox.path)).to_s.split(/\//).first
    collection = Admin::Collection.where(dropbox_directory_name_ssi: dropbox_directory).first
    return if collection.nil?

    ingest = Avalon::Batch::Ingest.new(collection)
    begin
      package = Avalon::Batch::Package.new(filename, collection)
      ingest.process_valid_package(package: package)
    rescue Exception => ex
      begin
        package.manifest.error!
      ensure
        Rails.logger.error("#{ex.class.name}: #{ex.message}")
        IngestBatchMailer.batch_ingest_validation_error(package, ["#{ex.class.name}: #{ex.message}"]).deliver_now
      end
    end
  end
end
