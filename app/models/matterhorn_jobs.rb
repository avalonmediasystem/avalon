class MatterhornJobs
  def send_request args
    logger.debug "<< Calling Matterhorn with arguments: #{args} >>"
    begin
      workflow_doc = Rubyhorn.client.addMediaPackageWithUrl(args)
    rescue Rubyhorn::RestClient::Exceptions::MissingRequiredParams => e
      update_master_file_with_failure(args['title'], e.message)
    rescue Rubyhorn::RestClient::Exceptions::ServerError => e
      update_master_file_with_failure(args['title'], e.message)
    end
  end

  def update_master_file_with_failure(pid, message)
    logger.error "<< Matterhorn Job (pid:#{pid}) failed: #{message} >>"
    master_file = MasterFile.find(pid)
    # add message here to update master file
    master_file.status_code = 'FAILED'
    master_file.error = message
    master_file.save
  end

  # Errno::ECONNREFUSED exception also possible if felix isn't running.
  # This exception should be recoverable, so Delayed Job should have 
  # the opportunity to try it again.  The same for Timeout::Error.

  handle_asynchronously :send_request
end
