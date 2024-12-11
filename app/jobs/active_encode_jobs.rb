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

module ActiveEncodeJobs
  class CreateEncodeJob < ActiveJob::Base
    queue_as :create_encode

    def perform(input, master_file_id, options = {})
      return unless MasterFile.exists? master_file_id
      master_file = MasterFile.find(master_file_id)
      return if master_file.workflow_id.present?
      master_file.encoder_class.create(input, options.merge!(master_file_id: master_file_id, preset: master_file.workflow_name, extract_subtitles: true))
    end
  end

  class CancelEncodeJob < ActiveJob::Base
    def perform(workflow_id, master_file_id)
      return unless MasterFile.exists? master_file_id
      master_file = MasterFile.find(master_file_id)
      return if master_file.finished_processing?
      master_file.encoder_class.find(workflow_id).try(:cancel!)
    end
  end
end
