class AddDropboxToCollections < ActiveRecord::Migration
  def up
    Admin::Collection.find_each({},{batch_size:5}) do |collection|
      if ! collection.dropbox_directory_name
        collection.send(:create_dropbox_directory!)
        collection.save( validate: false )
      end
    end
  end
end
