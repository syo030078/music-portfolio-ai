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

ActiveRecord::Schema[7.0].define(version: 2025_11_27_005437) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "client_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "organization"
    t.boolean "verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["user_id"], name: "index_client_profiles_on_user_id", unique: true
    t.index ["uuid"], name: "index_client_profiles_on_uuid", unique: true
  end

  create_table "contract_milestones", force: :cascade do |t|
    t.bigint "contract_id", null: false
    t.string "title", null: false
    t.integer "amount_jpy", null: false
    t.date "due_on"
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["contract_id"], name: "index_contract_milestones_on_contract_id"
    t.index ["status"], name: "index_contract_milestones_on_status"
    t.index ["uuid"], name: "index_contract_milestones_on_uuid", unique: true
  end

  create_table "contracts", force: :cascade do |t|
    t.bigint "proposal_id", null: false
    t.bigint "client_id", null: false
    t.bigint "musician_id", null: false
    t.string "status", default: "active", null: false
    t.integer "escrow_total_jpy", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["client_id"], name: "index_contracts_on_client_id"
    t.index ["musician_id"], name: "index_contracts_on_musician_id"
    t.index ["proposal_id"], name: "index_contracts_on_proposal_id", unique: true
    t.index ["status"], name: "index_contracts_on_status"
    t.index ["uuid"], name: "index_contracts_on_uuid", unique: true
  end

  create_table "conversation_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "conversation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "last_read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_participants_on_conversation_and_user", unique: true
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "job_id"
    t.bigint "contract_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_conversations_on_contract_id"
    t.index ["job_id"], name: "index_conversations_on_job_id"
    t.check_constraint "job_id IS NOT NULL AND contract_id IS NULL OR job_id IS NULL AND contract_id IS NOT NULL", name: "conversations_job_or_contract"
  end

  create_table "genres", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["name"], name: "index_genres_on_name", unique: true
    t.index ["uuid"], name: "index_genres_on_uuid", unique: true
  end

  create_table "instruments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["name"], name: "index_instruments_on_name", unique: true
    t.index ["uuid"], name: "index_instruments_on_uuid", unique: true
  end

  create_table "job_requirements", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "kind", null: false
    t.bigint "ref_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["job_id", "kind", "ref_id"], name: "index_job_requirements_unique", unique: true
    t.index ["job_id"], name: "index_job_requirements_on_job_id"
    t.index ["uuid"], name: "index_job_requirements_on_uuid", unique: true
  end

  create_table "jobs", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "track_id"
    t.text "description"
    t.integer "budget_jpy"
    t.string "status", default: "draft"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.integer "budget_min_jpy"
    t.integer "budget_max_jpy"
    t.date "delivery_due_on"
    t.boolean "is_remote", default: true
    t.text "location_note"
    t.datetime "published_at"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["client_id"], name: "index_jobs_on_client_id"
    t.index ["published_at"], name: "index_jobs_on_published_at"
    t.index ["status"], name: "index_jobs_on_status"
    t.index ["track_id"], name: "index_jobs_on_track_id"
    t.index ["uuid"], name: "index_jobs_on_uuid", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "conversation_id", null: false
    t.text "attachment_url"
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["uuid"], name: "index_messages_on_uuid", unique: true
  end

  create_table "musician_genres", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "genre_id", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["genre_id"], name: "index_musician_genres_on_genre_id"
    t.index ["user_id", "genre_id"], name: "index_musician_genres_on_user_id_and_genre_id", unique: true
    t.index ["user_id"], name: "index_musician_genres_on_user_id"
    t.index ["uuid"], name: "index_musician_genres_on_uuid", unique: true
  end

  create_table "musician_instruments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "instrument_id", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["instrument_id"], name: "index_musician_instruments_on_instrument_id"
    t.index ["user_id", "instrument_id"], name: "index_musician_instruments_on_user_id_and_instrument_id", unique: true
    t.index ["user_id"], name: "index_musician_instruments_on_user_id"
    t.index ["uuid"], name: "index_musician_instruments_on_uuid", unique: true
  end

  create_table "musician_profiles", force: :cascade do |t|
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
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["user_id"], name: "index_musician_profiles_on_user_id", unique: true
    t.index ["uuid"], name: "index_musician_profiles_on_uuid", unique: true
  end

  create_table "musician_skills", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "skill_id", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["skill_id"], name: "index_musician_skills_on_skill_id"
    t.index ["user_id", "skill_id"], name: "index_musician_skills_on_user_id_and_skill_id", unique: true
    t.index ["user_id"], name: "index_musician_skills_on_user_id"
    t.index ["uuid"], name: "index_musician_skills_on_uuid", unique: true
  end

  create_table "proposals", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "musician_id", null: false
    t.text "cover_message"
    t.integer "quote_total_jpy", null: false
    t.integer "delivery_days", null: false
    t.string "status", default: "submitted", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["job_id", "musician_id"], name: "index_proposals_on_job_id_and_musician_id", unique: true
    t.index ["job_id"], name: "index_proposals_on_job_id"
    t.index ["musician_id"], name: "index_proposals_on_musician_id"
    t.index ["status"], name: "index_proposals_on_status"
    t.index ["uuid"], name: "index_proposals_on_uuid", unique: true
  end

  create_table "skills", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["name"], name: "index_skills_on_name", unique: true
    t.index ["uuid"], name: "index_skills_on_uuid", unique: true
  end

  create_table "tracks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.text "description"
    t.string "yt_url"
    t.float "bpm"
    t.string "key"
    t.string "genre"
    t.text "ai_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["user_id", "created_at"], name: "index_tracks_on_user_id_and_created_at"
    t.index ["user_id", "yt_url"], name: "index_tracks_on_user_id_and_yt_url", unique: true
    t.index ["user_id"], name: "index_tracks_on_user_id"
    t.index ["uuid"], name: "index_tracks_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
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
    t.boolean "is_musician", default: false
    t.boolean "is_client", default: false
    t.datetime "deleted_at"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "client_profiles", "users"
  add_foreign_key "contract_milestones", "contracts"
  add_foreign_key "contracts", "proposals"
  add_foreign_key "contracts", "users", column: "client_id"
  add_foreign_key "contracts", "users", column: "musician_id"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "conversation_participants", "users"
  add_foreign_key "conversations", "contracts"
  add_foreign_key "conversations", "jobs"
  add_foreign_key "job_requirements", "jobs"
  add_foreign_key "jobs", "tracks"
  add_foreign_key "jobs", "users", column: "client_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "musician_genres", "genres"
  add_foreign_key "musician_genres", "users"
  add_foreign_key "musician_instruments", "instruments"
  add_foreign_key "musician_instruments", "users"
  add_foreign_key "musician_profiles", "users"
  add_foreign_key "musician_skills", "skills"
  add_foreign_key "musician_skills", "users"
  add_foreign_key "proposals", "jobs"
  add_foreign_key "proposals", "users", column: "musician_id"
  add_foreign_key "tracks", "users"
end
