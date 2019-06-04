class AddLimitToManifest < ActiveRecord::Migration[5.1]
  def change
    change_column :timelines, :manifest, :text, limit: 16777215
  end
end
