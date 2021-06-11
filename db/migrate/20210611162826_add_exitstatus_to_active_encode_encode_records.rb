class AddExitstatusToActiveEncodeEncodeRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :active_encode_encode_records, :exit_status, :integer
  end
end
