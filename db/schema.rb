# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160420024758) do

  create_table "blacklight_folders_folder_items", force: true do |t|
    t.integer  "folder_id",   null: false
    t.integer  "bookmark_id", null: false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blacklight_folders_folder_items", ["bookmark_id"], name: "index_blacklight_folders_folder_items_on_bookmark_id"
  add_index "blacklight_folders_folder_items", ["folder_id"], name: "index_blacklight_folders_folder_items_on_folder_id"

  create_table "blacklight_folders_folders", force: true do |t|
    t.string   "name"
    t.integer  "user_id",                       null: false
    t.string   "user_type",                     null: false
    t.string   "visibility"
    t.integer  "number_of_members", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blacklight_folders_folders", ["user_id", "user_type"], name: "index_blacklight_folders_folders_on_user_id_and_user_type"

  create_table "bookmarks", force: true do |t|
    t.integer  "user_id",                   null: false
    t.string   "document_id",   limit: nil
    t.string   "title",         limit: nil
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type",     limit: nil
    t.string   "document_type", limit: nil
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "courses", force: true do |t|
    t.string   "context_id", limit: nil
    t.text     "label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title",      limit: nil
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",               default: 0
    t.integer  "attempts",               default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: nil
    t.string   "queue",      limit: nil
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "identities", force: true do |t|
    t.string   "email",           limit: nil
    t.string   "password_digest", limit: nil
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ingest_batches", force: true do |t|
    t.string   "email",            limit: nil
    t.text     "media_object_ids"
    t.boolean  "finished",                     default: false
    t.boolean  "email_sent",                   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",             limit: 50
  end

  create_table "role_maps", force: true do |t|
    t.string  "entry",     limit: nil
    t.integer "parent_id"
  end

  create_table "searches", force: true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_type",    limit: nil
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "sessions", force: true do |t|
    t.string   "session_id",                  null: false
    t.text     "data",       limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "stream_tokens", force: true do |t|
    t.string   "token",   limit: nil
    t.string   "target",  limit: nil
    t.datetime "expires"
  end

  create_table "superusers", force: true do |t|
    t.integer "user_id", null: false
  end

  create_table "users", force: true do |t|
    t.string   "username",   limit: nil, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider",   limit: nil
    t.string   "uid",        limit: nil
    t.string   "email",      limit: nil
    t.string   "guest",      limit: nil
  end

  add_index "users", ["username"], name: "index_users_on_username", unique: true

end
