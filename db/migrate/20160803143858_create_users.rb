class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string   "username", null: false
      t.string   "email", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "provider"
      t.string   "uid"
      t.string   "guest"
    end

    add_index "users", ["username"], name: "index_users_on_username", unique: true
    add_index "users", ["email"], name: "index_users_on_email", unique: true
  end
end
