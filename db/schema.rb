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

ActiveRecord::Schema[8.0].define(version: 2025_03_05_095022) do
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

  create_table "messages", force: :cascade do |t|
    t.integer "assistant_id"
    t.string "role"
    t.text "content"
    t.json "tool_calls"
    t.string "tool_call_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "conversation_id", null: false
    t.index ["assistant_id"], name: "index_messages_on_assistant_id"
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

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "username", null: false
    t.string "phone"
    t.boolean "gender"
    t.date "birthday"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "assistants", "users"
  add_foreign_key "conversations", "assistants"
  add_foreign_key "conversations", "users"
  add_foreign_key "messages", "assistants"
  add_foreign_key "messages", "conversations"
  add_foreign_key "sessions", "users"
end
