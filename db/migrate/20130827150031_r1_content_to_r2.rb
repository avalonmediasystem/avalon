# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
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

class R1ContentToR2 < ActiveRecord::Migration
  def up
    say_with_time("R1->R2") do
      prefix = Avalon::Configuration.lookup('fedora.namespace')
      ActiveFedora::Base.reindex_everything("pid~#{prefix}:*")
      MediaObject.find_each({},{batch_size:5}) do |mo|
        mediaobject_to_r2(mo) if mo.current_migration.nil?
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def mediaobject_to_r2(mo)
    say("MediaObject #{mo.pid} #{mo.current_migration}->R2", :subitem)
    mo.parts_with_order.each { |mf| masterfile_to_r2(mf) }
    collection = R1ContentToR2.find_or_create_collection(mo.descMetadata.collection.last, mo.edit_users)
    mo.collection = collection
    mo.descMetadata.collection = []
    mo.descMetadata.remove_empty_nodes!
    [:read_groups,:discover_groups,:edit_groups].each do |attr|
      groups = mo.send(attr)
      if groups.include?('collection_manager')
        groups[groups.index('collection_manager')] = 'manager'
        mo.send(:"#{attr}=",groups)
      end
    end
    mo.save_as_version('R2', validate: false)
  end

  def masterfile_to_r2(mf)
    say("MasterFile #{mf.pid} #{mf.current_migration}->R2", :subitem)
    mf.derivatives.each { |d| derivative_to_r2(d) }
    mf.duration = mf.derivatives.empty? ? '0' : mf.derivatives.first.duration.to_s
    mf.descMetadata.poster_offset = mf.descMetadata.thumbnail_offset = [mf.duration.to_i,2000].min.to_s
    mf.save_as_version('R2', validate: false)
  end

  def derivative_to_r2(d)
    say("Derivative #{d.pid} #{d.current_migration}->R2", :subitem)
    d.save_as_version('R2', validate: false)
  end

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
end
