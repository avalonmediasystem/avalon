class AddAccessTokenToPlaylist < ActiveRecord::Migration
  def change
    add_column :playlists, :access_token, :string
  end
end
