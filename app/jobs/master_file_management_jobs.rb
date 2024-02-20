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

    def s3_to_s3(source, dest)
      source_object = FileLocator::S3File.new(source.source).object
      dest_object = FileLocator::S3File.new(dest.source).object
      if dest_object.copy_from(source_object, multipart_copy: source_object.size > 15.megabytes)
        source_object.delete if FileLocator.new(dest.source).exists?
      end
    end

    def s3_to_file(source, dest)
      source_object = FileLocator::S3File.new(source.source).object
      FileUtils.mkdir_p File.dirname(dest.uri.path) unless File.exist? File.dirname(dest.uri.path)
      if source_object.download_file(dest.uri.path)
        source_object.delete
      end
    end

    def file_to_s3(source, dest)
      dest_object = FileLocator::S3File.new(dest.source).object
      if dest_object.upload_file(source.uri.path)
        FileUtils.rm(source.uri.path)
      end
    end

    def file_to_file(source, dest)
    	FileUtils.mkdir_p File.dirname(dest.location) unless File.exist? File.dirname(dest.location)
    	FileUtils.mv source.location, dest.location
    end

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
        send(copy_method, old_locator, new_locator)
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
      	masterfile.file_location = ""
      	masterfile.save
      	Rails.logger.info "#{oldpath} has been deleted"
      else
      	unless masterfile.file_location.empty?
      	  masterfile.file_location = ""
      	  masterfile.save
      	end
      	Rails.logger.warn "MasterFile #{oldpath} does not exist"
      end
    end
  end
end
