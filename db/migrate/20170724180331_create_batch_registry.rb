class CreateBatchRegistry < ActiveRecord::Migration
  def change
    create_table :batch_registries do |t|
      t.string   "file_name", null: false
      t.string   "replay_name", null: false
      t.string   "collection", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "valid_manifest"
      t.boolean  "completed"
      t.boolean  "email_sent"
    end
  end
end
