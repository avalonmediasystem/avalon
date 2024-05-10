# Copyright 2011-2024, The Trustees of Indiana University and Northwestern
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

class ApplicationJob < ActiveJob::Base
  rescue_from RSolr::Error::ConnectionRefused, :with => :handle_connection_error
  rescue_from RSolr::Error::Timeout, :with => :handle_connection_error
  rescue_from Blacklight::Exceptions::ECONNREFUSED, :with => :handle_connection_error
  rescue_from Faraday::ConnectionFailed, :with => :handle_connection_error

  rescue_from Ldp::Gone do |exception|
    Rails.logger.error(exception.message + '\n' + exception.backtrace.join('\n'))
  end

  private
    def handle_connection_error(exception)
      raise if Settings.app_job.solr_and_fedora.raise_on_connection_error
      Rails.logger.error(exception.class.to_s + ': ' + exception.message + '\n' + exception.backtrace.join('\n'))
    end
end
