# Copyright 2011-2022, The Trustees of Indiana University and Northwestern
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

#Handles the registration of individual ingests for batch
#@since 6.3.0

require 'acts_as_list'

class BatchEntries < ActiveRecord::Base
  belongs_to :batch_registries
  acts_as_list scope: :batch_registries
  before_save :ensure_mininum_viable_metadata

  # Determines if we have the mininum viable metadata needed to ingest an object
  # Sets an error on the row when we do not
  def ensure_mininum_viable_metadata
    return nil if  minimal_viable_metadata?
    self.error = true
    self.error_message = 'To successfully ingest, either title and date issued must be set or a bibliographic id must be provided'
  end

  def queue
    IngestBatchEntryJob.perform_later(self)
    self.current_status = 'Queued'
    self.save
  end

  def encoding_success?
    encoding_status == :success
  end

  def encoding_error?
    encoding_status == :error
  end

  def encoding_finished?
    encoding_success? || encoding_error?
  end

  private

  def minimal_viable_metadata?
    return false if payload.nil? # nil guard
    fields = JSON.parse(payload)['fields']
    return false if fields.blank?
    return false if (fields['date_issued'].blank? || fields['title'].blank?) && fields['bibliographic_id'].blank?
    true
  end

  def files
    @files ||= JSON.parse(payload)['files']
  end

  # Returns :success, :error, or :in_progress
  def encoding_status
    return @encoding_status if @encoding_status.present?

    # Issues with the MediaObject are treated as encoding errors
    return (@encoding_status = :error) if media_object_pid.blank?
    # Using where instead of find to avoid throwing a not found exception
    media_object = MediaObject.where(id: media_object_pid).first
    return (@encoding_status = :error) unless media_object

    # TODO: match file_locations strings with those in MasterFiles?
    if media_object.master_files.to_a.count != files.count
      return (@encoding_status = :error)
    end

    # Only return success if all MasterFiles have status 'COMPLETED'
    status = :success
    media_object.master_files.each do |master_file|
      next if master_file.status_code == 'COMPLETED'
      # TODO: explore border cases
      if master_file.status_code == 'FAILED' || master_file.status_code == 'CANCELLED'
        status = :error
      else
        status = :in_progress
        break
      end
    end
    @encoding_status = status
    @encoding_status
  end
end
