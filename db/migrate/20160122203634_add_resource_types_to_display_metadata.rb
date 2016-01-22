class AddResourceTypesToDisplayMetadata < ActiveRecord::Migration

  def up
    say_with_time("Add resource types to displaymetadata") do
      MediaObject.find_each({},{batch_size:5}) do |mo| 
        mo.set_resource_types!
        mo.save
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
