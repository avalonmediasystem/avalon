class BatchIngestMailer < ActionMailer::Base

  def status_email( ingest_batch_id )
    @ingest_batch = IngestBatch.find(ingest_batch_id)
    @media_objects = @ingest_batch.media_objects
    mail(:to => 'adam.t.hallett@gmail.com', :from => 'adam.hallett@northwestern.edu', :subject => 'Batch Ingest Status')
  end

end