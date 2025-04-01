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

class AddDefaultBooleanValuesToBatchRegistriesAndBatchEntries < ActiveRecord::Migration[5.1]
  def change
    change_column :batch_registries, :complete, :boolean, null: false, default: false
    change_column :batch_registries, :error, :boolean, null: false, default: false
    change_column :batch_registries, :processed_email_sent, :boolean, null: false, default: false
    change_column :batch_registries, :completed_email_sent, :boolean, null: false, default: false
    change_column :batch_registries, :error_email_sent, :boolean, null: false, default: false
    change_column :batch_registries, :locked, :boolean, null: false, default: false

    change_column :batch_entries, :complete, :boolean, null: false, default: false
    change_column :batch_entries, :error, :boolean, null: false, default: false
  end
end
