# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

class BatchIngestJob < ActiveJob::Base
  queue_as :batch_ingest
  def perform(filename)
    return unless Avalon::Batch::Manifest.is_spreadsheet?(filename) && Avalon::Batch::S3Manifest.status(filename).blank?

    uri = Addressable::URI.parse(filename)
    dropbox_directory = uri.route_from(Addressable::URI.parse(Settings.dropbox.path)).to_s.split(/\//).first
    collection = Admin::Collection.where(dropbox_directory_name_ssi: dropbox_directory).first
    return if collection.nil?

    ingest = Avalon::Batch::Ingest.new(collection)
    begin
      package = Avalon::Batch::Package.new(filename, collection)
      ingest.ingest_package(package)
    rescue Exception => ex
      begin
        package.manifest.error!
      ensure
        Rails.logger.error("#{ex.class.name}: #{ex.message}")
        IngestBatchMailer.batch_ingest_validation_error( package, ["#{ex.class.name}: #{ex.message}"] ).deliver_now
      end
    end
  end
end
