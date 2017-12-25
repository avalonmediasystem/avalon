class CreateBatchEntries < ActiveRecord::Migration
  def change
    create_table :batch_entries do |t|
      t.belongs_to :batch_registries, index: true
      t.text 'payload', limit: 1_073_741_823
      t.boolean 'complete'
      t.boolean 'error'
      t.string 'current_status'
      t.text 'error_message', limit: 65_535
      t.string 'media_object_pid'
      t.integer 'position', index: true
      t.timestamps
    end
  end
end
