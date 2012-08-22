class WorkflowStatus < ActiveRecord::Migration
  def change
    create_table :workflow_statuses do |t|
      t.string :pid
      t.string :current_step
      t.boolean :completed
    end
  end
end
