# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

class AvalonJobs
  def self.move_masterfile pid, newpath
    logger.debug "Moving masterfile to #{newpath}"

    masterfile = MasterFile.find(pid)
    oldpath = masterfile.file_location
    if File.exist? oldpath 
      FileUtils.mkdir_p File.dirname(newpath) unless File.exist? File.dirname(newpath)
      FileUtils.mv oldpath, newpath
      masterfile.file_location = newpath
      masterfile.save
      logger.info "#{oldpath} has been moved to #{newpath}"
    else 
      logger.error "MasterFile #{oldpath} does not exist"
    end
  end

  def self.delete_masterfile pid 
    logger.debug "Deleting masterfile"

    masterfile = MasterFile.find(pid)
    oldpath = masterfile.file_location
    if File.exist? oldpath
      File.delete(oldpath) 
      masterfile.file_location = ""
      masterfile.save
      logger.info "#{oldpath} has been deleted"
    else
      unless masterfile.file_location.empty?
        masterfile.file_location = ""
        masterfile.save
      end
      logger.warn "MasterFile #{oldpath} does not exist"
    end
  end
class << self
  handle_asynchronously :delete_masterfile
  handle_asynchronously :move_masterfile
  
end

end
