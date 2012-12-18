class BatchIngestMailer < ActionMailer::Base

  # workflow id should be passed in
  # worfklow should be able to be looked up in delayed job
  # delayed job should look up all the media objects from the workflow id
  def status_email( media_objects,  batch_ingest = nil )
    @media_objects = media_objects
    mail(:to => 'adam.t.hallett@gmail.com', :from => 'adam.hallett@northwestern.edu', :subject => 'Batch Ingest Status')
  end

end