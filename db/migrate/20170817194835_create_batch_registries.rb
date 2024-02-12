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

class CreateBatchRegistries < ActiveRecord::Migration[5.1]
  def change
    create_table :batch_registries do |t|
      t.string 'file_name'
      t.string 'replay_name'
      t.string 'dir'
      t.integer 'user_id'
      t.string 'collection'
      t.boolean 'complete'
      t.boolean 'processed_email_sent'
      t.boolean 'completed_email_sent'
      t.boolean 'error'
      t.text 'error_message'
      t.boolean 'error_email_sent'
      t.boolean 'locked'
      t.timestamps
    end
  end
end
