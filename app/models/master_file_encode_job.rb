class MasterFileEncodeJob < Struct.new(:master_file_id, :encode)
  def perform
    if !encode.created?
      MasterFile.find(master_file_id).update_progress!(encode.create!).save
    else
      MasterFile.find(master_file_id).update_progress!(encode.reload).save
    end
  end

  def after(job)
    reschedule(job, 5.seconds.from_now) if job.payload_object.encode.running?
  end

  def error(job, exception)
    master_file = MasterFile.find(job.payload_object.master_file_id)
    # add message here to update master file
    master_file.status_code = 'FAILED'
    master_file.error = exception.message
    master_file.save
  end
end
