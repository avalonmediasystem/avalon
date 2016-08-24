# This migration comes from active_annotations (originally 20160422052041)
class CreateAnnotation < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.string :uuid
      t.string :source_uri
      t.text   :annotation
      t.string :type
    end
    add_index :annotations, :type
  end
end
