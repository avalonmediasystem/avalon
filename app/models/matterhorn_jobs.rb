# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

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
