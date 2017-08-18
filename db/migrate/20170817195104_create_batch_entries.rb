class CreateBatchEntries < ActiveRecord::Migration
  def change
    create_table :batch_entries do |t|
      t.belongs_to :batch_registries, index: true
      t.text 'payload', limit: 4294967295
      t.boolean 'complete'
      t.boolean 'error'
      t.string 'current_status'
      t.string 'error_message'
      t.string 'media_object_pid'
    end
  end
end
