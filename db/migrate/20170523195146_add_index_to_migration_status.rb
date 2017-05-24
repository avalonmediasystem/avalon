class AddIndexToMigrationStatus < ActiveRecord::Migration
  def change
    add_index :migration_statuses, [:source_class, :f3_pid, :datastream], name: :index_migration_statuses
  end
end
