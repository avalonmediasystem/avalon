class MediaObjectMigration < Hydra::Migrate::Migration
  def find_or_create_collection(name, managers)
    # Make sure all managers are in the global manager group
    manager_group = Admin::Group.find('manager') or Admin::Group.find('collection_manager')
    if manager_group.name == 'collection_manager' or managers.any? { |m| ! manager_group.users.include? m }
      manager_group.name = 'manager'
      manager_group.users = (manager_group.users + managers).uniq
      manager_group.save
    end

    # Find or create the collection with the specified name
    name ||= 'NO COLLECTION'
    collection = Admin::Collection.find(:name_tesim => collection_name).first
    if collection.nil?
      Admin::Collection.create(name: name, managers: managers, unit: Admin::Collection.units.first)
    end
    collection.managers = (collection.managers + managers).uniq
    collection.save
    collection
  end

  migrate nil => 'R2' do |obj,ver,dispatcher|
    dispatcher.migrate!(obj.parts)
    collection = find_or_create_collection(obj.descMetadata.collection.last, obj.edit_users)
    obj.collection = collection
    obj.descMetadata.collection = []
    obj.descMetadata.remove_empty_nodes!
  end
end
