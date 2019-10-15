# This migration comes from hyrax_active_encode (originally 20190712191231)
class AddSortFieldsToActiveEncodeEncodeRecords < ActiveRecord::Migration[5.1]
  def change
    add_column :active_encode_encode_records, :display_title, :string
    add_index :active_encode_encode_records, :display_title
    add_column :active_encode_encode_records, :master_file_id, :string
    add_index :active_encode_encode_records, :master_file_id
    add_column :active_encode_encode_records, :media_object_id, :string
    add_index :active_encode_encode_records, :media_object_id
  end
end
