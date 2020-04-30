class CreateSupplementalFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :supplemental_files do |t|
      t.string :label

      t.timestamps
    end
  end
end
