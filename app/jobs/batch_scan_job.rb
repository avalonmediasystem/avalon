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
