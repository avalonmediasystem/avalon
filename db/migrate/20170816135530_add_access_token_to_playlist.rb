class AddAccessTokenToPlaylist < ActiveRecord::Migration[5.1]
  def change
    add_column :playlists, :access_token, :string
  end
end
