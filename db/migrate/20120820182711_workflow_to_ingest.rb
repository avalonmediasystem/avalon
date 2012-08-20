class WorkflowToIngest < ActiveRecord::Migration
  def change
    rename_table :workflow_statuses, :ingest_statuses
  end
end
