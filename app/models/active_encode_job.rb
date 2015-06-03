module ActiveEncodeJob
  module Core
    def error(job, exception)
      master_file = MasterFile.find(job.payload_object.master_file_id)
      # add message here to update master file
      master_file.status_code = 'FAILED'
      master_file.error = exception.message
      master_file.save
    end
  end

  class Create < Struct.new(:master_file_id, :encode)
    include ActiveEncodeJob::Core
    def perform
      unless encode.created?
        Delayed::Worker.logger.info "Creating! #{encode.inspect} for MasterFile #{master_file_id}"
        MasterFile.find(master_file_id).update_progress_with_encode!(encode.create!).save
        Delayed::Job.enqueue(ActiveEncodeJob::Update.new(master_file_id), run_at: 10.seconds.from_now)
      end
    end
  end

  class Update < Struct.new(:master_file_id)
    include ActiveEncodeJob::Core  #I'm not sure if the error callback is really makes sense here!
    def perform
      Delayed::Worker.logger.info "Updating encode progress for MasterFile: #{master_file_id}"
      mf = MasterFile.find(master_file_id)
      mf.update_progress!
      mf.save
      mf.reload
      Delayed::Job.enqueue(ActiveEncodeJob::Update.new(master_file_id), run_at: 10.seconds.from_now) unless mf.finished_processing?
    end
  end
end
