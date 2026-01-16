class ChangePlaylistsCommentToText < ActiveRecord::Migration[8.0]
  def change
    change_column :playlists, :comment, :text, limit: 65_535
  end
end
