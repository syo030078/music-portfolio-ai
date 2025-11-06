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

ActiveRecord::Schema[7.0].define(version: 2025_11_06_030620) do
  create_table "client_profiles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "organization"
    t.boolean "verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_client_profiles_on_user_id", unique: true
  end

  create_table "jobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "track_id", null: false
    t.text "description"
    t.integer "budget"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["track_id"], name: "index_jobs_on_track_id"
    t.index ["user_id"], name: "index_jobs_on_user_id"
  end

  create_table "jwt_denylists", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "messages", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "user_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_messages_on_job_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "musician_profiles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "headline"
    t.text "bio"
    t.integer "hourly_rate_jpy"
    t.boolean "remote_ok", default: false
    t.boolean "onsite_ok", default: false
    t.string "portfolio_url"
    t.decimal "avg_rating", precision: 2, scale: 1, default: "0.0"
    t.integer "rating_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_musician_profiles_on_user_id", unique: true
  end

  create_table "tracks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "title"
    t.text "description"
    t.string "yt_url"
    t.float "bpm"
    t.string "key"
    t.string "genre"
    t.text "ai_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_tracks_on_user_id_and_created_at"
    t.index ["user_id", "yt_url"], name: "index_tracks_on_user_id_and_yt_url", unique: true
    t.index ["user_id"], name: "index_tracks_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "provider"
    t.text "bio"
    t.string "uid"
    t.string "display_name"
    t.string "timezone", default: "UTC"
    t.boolean "is_musician", default: false, null: false
    t.boolean "is_client", default: false, null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "client_profiles", "users"
  add_foreign_key "jobs", "tracks"
  add_foreign_key "jobs", "users"
  add_foreign_key "messages", "jobs"
  add_foreign_key "messages", "users"
  add_foreign_key "musician_profiles", "users"
  add_foreign_key "tracks", "users"
end
