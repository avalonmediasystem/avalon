class CreateTableUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.string :name, limit: 100, unique: true
      t.text :created_by_user_id
      t.timestamps
    end
  end
end
