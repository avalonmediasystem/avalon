class ChangeAvalonAnnotationToAvalonClip < ActiveRecord::Migration
  def change
    rename_column :playlist_items, :annotation_id, :clip_id
  end
end
