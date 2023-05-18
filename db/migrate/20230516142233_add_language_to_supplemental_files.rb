class AddLanguageToSupplementalFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :supplemental_files, :language, :string
  end
end
