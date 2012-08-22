class ChangeIngestStatusFlag < ActiveRecord::Migration
  def change
    rename_column :ingest_statuses, :completed, :published
  end
end
