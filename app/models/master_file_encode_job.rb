class MasterFileEncodeJob < Struct.new(:master_file_id, :encode)
  def perform
    encode.create!
    #TODO while encode.running? update masterfile
  end

  def error(job, exception)
    master_file = MasterFile.find(job.payload_object.master_file_id)
    # add message here to update master file
    master_file.status_code = 'FAILED'
    master_file.error = exception.message
    master_file.save
  end
end

