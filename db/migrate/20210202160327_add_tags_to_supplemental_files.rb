class AddTagsToSupplementalFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :supplemental_files, :tags, :string
  end
end
