class CreateAdminApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_application_settings do |t|
      t.text :name
      t.json :master_file_management
      t.json :bib_retrieve
      t.json :dropbox
      t.json :email
      t.text :accessibility_request_link
      t.json :flash_message
      t.json :auth
      t.json :recaptcha
      t.text :google_analytics_tracking_id
      t.json :supplemental_files
      t.json :waveform
      t.json :controller_digital_lending
      t.json :caption_default
      t.json :home_page
      t.boolean :repository_read_only_mode
      t.text :repository_read_only_mode_message
      t.json :accessibility_compliance
      t.json :intercom
      t.integer :singleton_guard, default: 0, null: false

      t.timestamps
    end

    add_index :admin_application_settings, :singleton_guard, unique: true
  end
end
