# frozen_string_literal: true
# Copyright 2011-2020, The Trustees of Indiana University and Northwestern
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

class DeleteDropboxJob < ActiveJob::Base
  queue_as :default
  def perform(path)
    Rails.logger.debug "Attempting to delete dropbox directory #{path}"
    locator = FileLocator.new(path)
    begin
      if Settings.dropbox.path.match? %r{^s3://}
        locator.destroy_s3_dropbox_directory(path)
      else
        locator.destroy_fs_dropbox_directory(path)
      end
    rescue StandardError => err
      Rails.logger.warn "Error deleting dropbox directory #{path}: #{err.message}"
    end
  end
end