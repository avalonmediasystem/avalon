class AddTagsToPlaylist < ActiveRecord::Migration
  def change
    add_column :playlists, :tags, :string
  end
end
