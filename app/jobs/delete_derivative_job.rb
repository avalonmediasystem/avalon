# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

require 'fileutils'

class DeleteDerivativeJob < ActiveJob::Base
  queue_as :default

  def perform(path)
    Rails.logger.debug "Attempting to delete derivative #{path}"

    locator = FileLocator.new(path)
    if locator.exists?
      case locator.uri.scheme
      when 'file' then File.delete(locator.uri.path)
      when 's3'   then FileLocator::S3File.new(locator.source).object.delete
      end
      Rails.logger.info "#{path} has been deleted"
    else
      Rails.logger.warn "Derivative #{path} does not exist"
    end
  end
end
