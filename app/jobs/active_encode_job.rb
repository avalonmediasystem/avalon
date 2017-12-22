# Copyright 2011-2018, The Trustees of Indiana University and Northwestern
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

require 'active_encode'

module ActiveEncodeJob
  module Core
    def error(master_file, exception)
      unless master_file
        Rails.logger.error exception.message
        Rails.logger.error exception.backtrace.join("\n")
        return
      end

      # add message here to update master file
      master_file.status_code = 'FAILED'
      master_file.error = exception.message
      master_file.save
    end
  end

  class Create < ActiveJob::Base
    include ActiveEncodeJob::Core
    queue_as :active_encode_create
    def perform(master_file_id, input, options)
      mf = MasterFile.find(master_file_id)
      encode = mf.encoder_class.new(input, options.merge({output_key_prefix: "#{mf.id}/"}))
      unless encode.created?
        Rails.logger.info "Creating! #{encode.inspect} for MasterFile #{master_file_id}"
        encode_job = encode.create!
        raise RuntimeError, 'Error creating encoding job' unless encode_job.id.present?
        mf.update_progress_with_encode!(encode_job).save
        ActiveEncodeJob::Update.set(wait: 10.seconds).perform_later(master_file_id)
      end
    rescue StandardError => e
      error(mf, e)
    end
  end

  class Update < ActiveJob::Base
    include ActiveEncodeJob::Core  #I'm not sure if the error callback is really makes sense here!
    queue_as :active_encode_update
    def perform(master_file_id)
      Rails.logger.info "Updating encode progress for MasterFile: #{master_file_id}"
      mf = MasterFile.find(master_file_id)
      mf.update_progress!
      mf.save
      mf.reload
      ActiveEncodeJob::Update.set(wait: 10.seconds).perform_later(master_file_id) unless mf.finished_processing?
    rescue StandardError => e
      error(mf, e)
    end
  end
end
