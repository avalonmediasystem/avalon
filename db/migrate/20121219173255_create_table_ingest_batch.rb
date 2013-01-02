class CreateTableIngestBatch < ActiveRecord::Migration

  def change
    create_table :ingest_batches do |t|
      t.string :email
      t.text :media_object_ids
      t.boolean :finished, :default => false
      t.boolean :email_sent, :default => false
      t.timestamps
    end
  end
end
