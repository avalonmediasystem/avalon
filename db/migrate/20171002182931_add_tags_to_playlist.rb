class AddTagsToPlaylist < ActiveRecord::Migration[5.1]
  def change
    add_column :playlists, :tags, :string
  end
end
