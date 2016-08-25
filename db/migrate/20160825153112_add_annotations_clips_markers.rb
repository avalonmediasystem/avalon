class AddAnnotationsClipsMarkers < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.string :uuid
      t.string :source_uri
      t.text   :annotation
      t.string :type
    end
    add_index :annotations, :type
    create_table :playlists do |t|
      t.string :title
      t.references :user, null: false, index: true
      t.string :comment
      t.string :visibility
      t.timestamps
    end
    create_table :playlist_items do |t|
      t.references :playlist, null: false, index: true
      t.references :annotation, null: false, index: true
      t.integer :position
      t.timestamps
    end
    rename_column :playlist_items, :annotation_id, :clip_id
  end
end
