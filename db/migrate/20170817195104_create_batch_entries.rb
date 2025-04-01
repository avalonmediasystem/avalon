# Copyright 2011-2025, The Trustees of Indiana University and Northwestern
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

class CreateBatchEntries < ActiveRecord::Migration[5.1]
  def change
    create_table :batch_entries do |t|
      t.belongs_to :batch_registries, index: true
      t.text 'payload', limit: 1_073_741_823
      t.boolean 'complete'
      t.boolean 'error'
      t.string 'current_status'
      t.text 'error_message', limit: 65_535
      t.string 'media_object_pid'
      t.integer 'position', index: true
      t.timestamps
    end
  end
end
