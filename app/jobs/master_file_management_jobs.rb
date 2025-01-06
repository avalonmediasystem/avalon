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

require 'fileutils'

module MasterFileManagementJobs
  class Move < ActiveJob::Base
    queue_as :master_file_management_move

    def perform(id, newpath)
      Rails.logger.debug "Moving masterfile to #{newpath}"

      masterfile = MasterFile.find(id)
      oldpath = masterfile.file_location
      old_locator = FileLocator.new(oldpath)

      if newpath == oldpath
        Rails.logger.info "Masterfile #{newpath} already moved"
      elsif old_locator.exists?
        new_locator = FileLocator.new(newpath)
        copy_method = "#{old_locator.uri.scheme}_to_#{new_locator.uri.scheme}".to_sym
        FileMover.send(copy_method, old_locator, new_locator)
        masterfile.file_location = newpath
      	masterfile.save
        Rails.logger.info "#{oldpath} has been moved to #{newpath}"
      else
        Rails.logger.error "MasterFile #{oldpath} does not exist"
      end
    end
  end

  class Delete < ActiveJob::Base
    queue_as :master_file_management_delete
    def perform(id)
      Rails.logger.debug "Deleting masterfile"

      masterfile = MasterFile.find(id)
      oldpath = masterfile.file_location
      locator = FileLocator.new(oldpath)
      if locator.exists?
        case locator.uri.scheme
        when 'file' then File.delete(oldpath)
        when 's3'   then FileLocator::S3File.new(locator.source).object.delete
        end
      	Rails.logger.info "#{oldpath} has been deleted"
      else
      	Rails.logger.warn "MasterFile #{oldpath} does not exist"
      end
    end
  end
end
