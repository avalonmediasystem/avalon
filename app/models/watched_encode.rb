# frozen_string_literal: true
# Copyright 2011-2019, The Trustees of Indiana University and Northwestern
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

class WatchedEncode < ActiveEncode::Base
  include ::ActiveEncode::Persistence
  include ::ActiveEncode::Polling

  around_create do |encode, block|
    master_file_id = encode.options[:master_file_id]
    block.call
    master_file = MasterFile.find(master_file_id)
    master_file.update_progress_with_encode!(encode).save
  end

  after_status_update do |encode|
    record = ActiveEncode::EncodeRecord.find_by(global_id: encode.to_global_id.to_s)
    master_file_id = JSON.parse(record.create_options)['master_file_id']
    master_file = MasterFile.find(master_file_id)
    master_file.update_progress!
  end
end
