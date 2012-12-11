class MatterhornJobs
  def send_request args
    logger.debug "<< Calling Matterhorn with arguments: #{args} >>"
    begin
      workflow_doc = Rubyhorn.client.addMediaPackageWithUrl(args)
    rescue Timeout::Error => e
      logger.debug "<< Call to Matterhorn has timed out, but it's ok >>"
      logger.debug e
    end
  end

  handle_asynchronously :send_request
end
