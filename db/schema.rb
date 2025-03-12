# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_03_12_092914) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assistants", force: :cascade do |t|
    t.string "title", null: false
    t.string "instructions"
    t.string "tool_choice"
    t.json "tools"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_assistants_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.string "title", null: false
    t.integer "assistant_id", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_conversations_on_assistant_id"
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "knowledge_bases", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_knowledge_bases_on_name"
    t.index ["user_id"], name: "index_knowledge_bases_on_user_id"
  end

  create_table "knowledge_entries", force: :cascade do |t|
    t.string "title", null: false
    t.text "content"
    t.string "source_url"
    t.integer "knowledge_base_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_type", null: false
    t.index ["knowledge_base_id"], name: "index_knowledge_entries_on_knowledge_base_id"
    t.index ["source_type"], name: "index_knowledge_entries_on_source_type"
    t.index ["title"], name: "index_knowledge_entries_on_title"
  end

  create_table "messages", force: :cascade do |t|
    t.string "role"
    t.text "content"
    t.json "tool_calls"
    t.string "tool_call_id"
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "prompts", force: :cascade do |t|
    t.text "template", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tool_usages", force: :cascade do |t|
    t.string "function_name"
    t.json "arguments"
    t.text "result"
    t.string "status"
    t.integer "message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_usages_on_message_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "username", null: false
    t.string "phone"
    t.boolean "gender"
    t.date "birthday"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_used_assistant_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["last_used_assistant_id"], name: "index_users_on_last_used_assistant_id"
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assistants", "users"
  add_foreign_key "conversations", "assistants"
  add_foreign_key "conversations", "users"
  add_foreign_key "knowledge_bases", "users"
  add_foreign_key "knowledge_entries", "knowledge_bases"
  add_foreign_key "messages", "conversations"
  add_foreign_key "sessions", "users"
  add_foreign_key "tool_usages", "messages"
  add_foreign_key "users", "assistants", column: "last_used_assistant_id"
end
