class AddDefaultBooleanValuesToBatchRegistriesAndBatchEntries < ActiveRecord::Migration
  def change
    change_column :batch_registries, :complete, :boolean, null: false, default: false
    change_column :batch_registries, :error, :boolean, null: false, default: false
    change_column :batch_registries, :processed_email_sent, :boolean, null: false, default: false
    change_column :batch_registries, :completed_email_sent, :boolean, null: false, default: false
    change_column :batch_registries, :error_email_sent, :boolean, null: false, default: false
    change_column :batch_registries, :locked, :boolean, null: false, default: false

    change_column :batch_entries, :complete, :boolean, null: false, default: false
    change_column :batch_entries, :error, :boolean, null: false, default: false
  end
end
