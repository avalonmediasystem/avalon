class CreateMigrationStatuses < ActiveRecord::Migration
  def change
    create_table :migration_statuses do |t|
      t.string :source_class, null: false
      t.string :f3_pid, null: false
      t.string :f4_pid
      t.string :datastream
      t.string :checksum
      t.string :status
      t.text :log

      t.timestamps null: false
    end
  end
end
