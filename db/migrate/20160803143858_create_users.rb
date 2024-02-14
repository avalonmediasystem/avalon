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

class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string   "username", null: false
      t.string   "email", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "provider"
      t.string   "uid"
      t.string   "guest"
    end

    add_index "users", ["username"], name: "index_users_on_username", unique: true
    add_index "users", ["email"], name: "index_users_on_email", unique: true
  end
end
