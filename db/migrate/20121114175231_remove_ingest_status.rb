class RemoveIngestStatus < ActiveRecord::Migration
  def change
    drop_table :ingest_statuses
  end
end
