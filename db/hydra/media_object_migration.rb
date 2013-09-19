# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
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

class MediaObjectMigration < Hydra::Migrate::Migration
  def self.find_or_create_collection(name, managers)
    # Make sure all managers are in the global manager group
    RoleControls.assign_users(RoleControls.users('manager')|managers, 'manager')

    # Find or create the collection with the specified name
    name ||= 'Default Collection'
    collection = Admin::Collection.find(:name_tesim => name).first
    if collection.nil?
      collection = Admin::Collection.create(name: name, managers: managers, unit: Admin::Collection.units.first)
    end
    collection.managers = collection.managers | managers
    collection.save
    collection
  end

  migrate nil => 'R2' do |obj,ver,dispatcher|
    dispatcher.migrate!(obj.parts)
    collection = MediaObjectMigration.find_or_create_collection(obj.descMetadata.collection.last, obj.edit_users)
    obj.collection = collection
    obj.descMetadata.collection = []
    obj.descMetadata.remove_empty_nodes!
    [:read_groups,:discover_groups,:edit_groups].each do |attr|
      groups = obj.send(attr)
      if groups.include?('collection_manager')
        groups[groups.index('collection_manager')] = 'manager'
        obj.send(:"#{attr}=",groups)
      end
    end
  end
end
