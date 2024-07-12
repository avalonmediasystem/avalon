class AddParentIdToSupplementalFile < ActiveRecord::Migration[7.0]
  def change
    add_column :supplemental_files, :parent_id, :string
  end
end
