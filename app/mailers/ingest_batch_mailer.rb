class IngestBatchMailer < ActionMailer::Base

  def status_email( ingest_batch_id )
    @ingest_batch = IngestBatch.find(ingest_batch_id)
    @media_objects = @ingest_batch.media_objects
    @email = @ingest_batch.email || 'avalon-core-l@list.indiana.edu'
    mail(
      to: @email, 
      from: 'avalon-core-l@list.indiana.edu', 
      subject: "Batch ingest status for: #{@ingest_batch.name}"
    )
  end

end