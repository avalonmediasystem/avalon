class AddPendingToBatchRegistries < ActiveRecord::Migration
  def change
    add_column :batch_registries, :locked, :boolean
  end
end
