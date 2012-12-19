class CreateTableIngestBatch < ActiveRecord::Migration

  def change
    create_table :ingest_batches do |t|
      t.text :media_object_ids
      t.string :email
      t.boolean :finished, :default => false
      t.timestamps
    end
  end
end
