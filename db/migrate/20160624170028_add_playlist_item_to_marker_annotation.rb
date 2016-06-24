class AddPlaylistItemToMarkerAnnotation < ActiveRecord::Migration
  def change
    add_reference :annotations, :playlist_item, index: true
  end
end
