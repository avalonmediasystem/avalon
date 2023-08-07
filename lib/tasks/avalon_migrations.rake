# Copyright 2011-2023, The Trustees of Indiana University and Northwestern
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

namespace :avalon do
  namespace :migrate do
    desc "Set new collection managers property on collection model as part of bugfix allowing users that belong to the manager group to be given the editor role"
    task collection_managers: :environment do
      Admin::Collection.all.each do |collection|
        next unless collection.collection_managers.blank?
        # initialize to old behavior
        collection.collection_managers = collection.edit_users & ( Avalon::RoleControls.users("manager") | (Avalon::RoleControls.users("administrator") || []) )
        collection.save!(validate: false)
      end
    end
  end
end
