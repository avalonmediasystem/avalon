class AddNameToIngestBatch < ActiveRecord::Migration
  def change
    add_column :ingest_batches, :name, :string, :limit => 50
  end
end
