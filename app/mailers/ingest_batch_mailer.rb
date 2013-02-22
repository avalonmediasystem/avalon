class IngestBatchMailer < ActionMailer::Base
  layout 'mailer'

  def status_email( ingest_batch_id )
    @ingest_batch = IngestBatch.find(ingest_batch_id)
    @media_objects = @ingest_batch.media_objects
    @email = @ingest_batch.email || Avalon::Configuration['email']['notification']
    mail(
      to: @email, 
      from: Avalon::Configuration['email']['notification'], 
      subject: "Batch ingest status for: #{@ingest_batch.name}"
    )
  end

  def batch_ingest_validation_error( package )
    @package = package
    email = package.manifest.email || Avalon::Configuration['email']['notification']
    mail(
      to: email,
      from: Avalon::Configuration['email']['notification'],
      subject: "Failed batch ingest processing errors for: #{package.manifest.name}",
    )
  end

  def batch_ingest_validation_success( package )
    @package = package
    email = package.manifest.email || Avalon::Configuration['email']['notification']
    mail(
      to: email,
      from: Avalon::Configuration['email']['notification'],
      subject: "Successfully processed batch ingest: #{package.manifest.name}",
    )
  end

end