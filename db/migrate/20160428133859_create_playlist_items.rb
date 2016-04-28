class CreatePlaylistItems < ActiveRecord::Migration
  def change
    create_table :playlist_items do |t|
      t.references :playlist, null: false, index: true
      t.references :annotation, null: false, index: true
      t.integer :position

      t.timestamps
    end
  end
end
