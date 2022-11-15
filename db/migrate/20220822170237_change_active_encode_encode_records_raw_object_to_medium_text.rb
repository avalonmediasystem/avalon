class ChangeActiveEncodeEncodeRecordsRawObjectToMediumText < ActiveRecord::Migration[6.0]
  def change
    change_column :active_encode_encode_records, :raw_object, :text, limit: 16777215
  end
end
