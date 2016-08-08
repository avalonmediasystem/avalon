class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string   "username",   default: "", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "provider"
      t.string   "uid"
      t.string   "email"
      t.string   "guest"
    end

    add_index "users", ["username"], name: "index_users_on_username", unique: true
  end
end
