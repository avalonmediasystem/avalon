class CreateTimelines < ActiveRecord::Migration[5.1]
  def change
    create_table :timelines do |t|
      t.string :title
      t.references :user, foreign_key: true
      t.string :visibility
      t.text :description
      t.string :access_token
      t.string :tags
      t.string :source
      t.text :manifest

      t.timestamps
    end
  end
end
