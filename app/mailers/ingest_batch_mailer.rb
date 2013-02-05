class IngestBatchMailer < ActionMailer::Base

  def status_email( ingest_batch_id )
    @ingest_batch = IngestBatch.find(ingest_batch_id)
    @media_objects = @ingest_batch.media_objects
    @email = @ingest_batch.email || Hydrant::Configuration['email']['notification']
    mail(
      to: @email, 
      from: Hydrant::Configuration['email']['notification'], 
      subject: "Batch ingest status for: #{@ingest_batch.name}"
    )
  end

end