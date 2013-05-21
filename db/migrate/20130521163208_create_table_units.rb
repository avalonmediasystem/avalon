class CreateTableUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.string :name, limit: 100
      t.timestamps
    end
  end
end
