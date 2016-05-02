class CreatePlaylists < ActiveRecord::Migration
  def change
    create_table :playlists do |t|
      t.string :title
      t.references :user, null: false, index: true
      t.string :comment
      t.string :visibility

      t.timestamps
    end
  end
end
