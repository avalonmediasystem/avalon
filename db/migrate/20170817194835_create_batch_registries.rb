class CreateBatchRegistries < ActiveRecord::Migration
  def change
    create_table :batch_registries do |t|
      t.string 'file_name'
      t.string 'replay_name'
      t.integer 'user_id'
      t.string 'collection'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.boolean 'complete'
      t.boolean 'processed_email_sent'
      t.boolean 'completed_email_sent'
      t.boolean 'error'
      t.text 'error_message'
      t.boolean 'error_email_sent'
      t.boolean 'locked'
    end
  end
end
