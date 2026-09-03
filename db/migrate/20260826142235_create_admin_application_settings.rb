class CreateAdminApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_application_settings do |t|
      t.jsonb :options, default: {}
      t.integer :singleton_guard, default: 0, null: false

      t.timestamps
    end

    add_index :admin_application_settings, :singleton_guard, unique: true
  end
end
