class MatterhornJobs
  def send_request args
    logger.debug "<< Calling Matterhorn with arguments: #{args} >>"
    logger.debug Rubyhorn.client.methods.inspect
    workflow_doc = Rubyhorn.client.addMediaPackageWithUrl(args)
  end
  handle_asynchronously :send_request
end
