class R2GroupMigration < ActiveRecord::Migration
  def up
    # Stuff goes here
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
