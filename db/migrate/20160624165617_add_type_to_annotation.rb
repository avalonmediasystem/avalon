class AddTypeToAnnotation < ActiveRecord::Migration
  def change
    add_column :annotations, :type, :string
    add_index :annotations, :type
  end
end
