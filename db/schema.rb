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

ActiveRecord::Schema.define(version: 20160824181325) do

  create_table "annotations", force: :cascade do |t|
    t.string "uuid"
    t.string "source_uri"
    t.text   "annotation"
    t.string "type"
  end

  add_index "annotations", ["type"], name: "index_annotations_on_type"

  create_table "api_tokens", force: :cascade do |t|
    t.string   "token",      null: false
    t.string   "username",   null: false
    t.string   "email",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_tokens", ["token"], name: "index_api_tokens_on_token", unique: true
  add_index "api_tokens", ["username"], name: "index_api_tokens_on_username"

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       null: false
    t.string   "user_type"
    t.string   "document_id"
    t.string   "document_type"
    t.string   "title"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "bookmarks", ["document_id"], name: "index_bookmarks_on_document_id"
  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "courses", force: :cascade do |t|
    t.string   "context_id"
    t.string   "title"
    t.text     "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0
    t.integer  "attempts",   default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "ingest_batches", force: :cascade do |t|
    t.string   "name",             limit: 50
    t.string   "email"
    t.text     "media_object_ids"
    t.boolean  "finished",                    default: false
    t.boolean  "email_sent",                  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "role_maps", force: :cascade do |t|
    t.string  "entry"
    t.integer "parent_id"
  end

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.string   "user_type"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "stream_tokens", force: :cascade do |t|
    t.string   "token"
    t.string   "target"
    t.datetime "expires"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",   null: false
    t.string   "email",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
    t.string   "guest"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["username"], name: "index_users_on_username", unique: true

end
