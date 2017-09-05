class CreateBatchRegistries < ActiveRecord::Migration
  def change
    create_table :batch_registries do |t|
      t.string 'file_name'
      t.string 'replay_name'
      t.string 'dir'
      t.integer 'user_id'
      t.string 'collection'
      t.boolean 'complete'
      t.boolean 'processed_email_sent'
      t.boolean 'completed_email_sent'
      t.boolean 'error'
      t.text 'error_message'
      t.boolean 'error_email_sent'
      t.boolean 'locked'
      t.timestamps
    end
  end
end
