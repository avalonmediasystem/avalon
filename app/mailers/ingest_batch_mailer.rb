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

class IngestBatchMailer < ActionMailer::Base
  layout 'mailer'

  def status_email( ingest_batch_id )
    @ingest_batch = IngestBatch.find(ingest_batch_id)
    @media_objects = @ingest_batch.media_objects
    @email = @ingest_batch.email || Settings.email.notification
    mail(
      to: @email, 
      from: Settings.email.notification, 
      subject: "Batch ingest status for: #{@ingest_batch.name}"
    )
  end

  def batch_ingest_validation_error( package, base_errors )
    @package = package
    @base_errors = base_errors
    email = package.manifest.email || Settings.email.notification
    mail(
      to: email,
      from: Settings.email.notification,
      subject: "Failed batch ingest processing errors for: #{package.manifest.name}",
    )
  end

  def batch_ingest_validation_success( package )
    @package = package
    email = package.manifest.email || Settings.email.notification
    mail(
      to: email,
      from: Settings.email.notification,
      subject: "Successfully processed batch ingest: #{package.manifest.name}",
    )
  end

end
