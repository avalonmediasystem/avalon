class MediaObjectMigration < Hydra::Migrate::Migration
  def initialize(*args)
    super
    
    if Admin::Collection.count == 0
      # Gather list of collections to be created and their managers

      new_collections = MediaObject.find(:all).inject(Hash.new {|h,k|h[k]=[]}) { |h,obj| 
        k = obj.descMetadata.collection.last
        h[k] = (h[k]+obj.edit_users).uniq
        h 
      }

      # Make sure all managers are in the managers group

      manager_group = Admin::Group.find('manager') or Admin::Group.find('collection_manager')
      manager_group.name = 'manager'
      manager_group.users = (manager_group.users + new_collections.values.flatten).uniq
      manager_group.save

      # Create collections

      new_collections.each_pair { |name, managers|
        name ||= 'NO COLLECTION'
        Admin::Collection.create(name: name, managers: managers)
      }
    end  
  end

  migrate nil => 'R2' do |obj,ver,dispatcher|
    dispatcher.migrate!(obj.parts)
    collection_name = obj.descMetadata.collection.last || 'NO COLLECTION'
    obj.collection = Admin::Collection.find_by_name(collection_name)
    obj.descMetadata.collection = []
    obj.descMetadata.remove_empty_nodes!
  end
end
