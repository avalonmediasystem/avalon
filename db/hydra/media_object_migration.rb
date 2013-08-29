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
