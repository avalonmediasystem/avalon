class CreateRoleMap < ActiveRecord::Migration
  def change
    create_table :role_maps do |t|
      t.string :entry
      t.integer :parent_id
    end
  end
end
