
ActiveRecord::Schema[8.1].define(version: 2026_10_26_132500) do
  create_table "participants", force: :cascade do |t|
    t.integer "tasting_session_id", null: false
    t.string "name", limit: 25, null: false
    t.string "session_token", null: false
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_token"], name: "index_participants_on_session_token", unique: true
    t.index ["tasting_session_id"], name: "index_participants_on_tasting_session_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.integer "round_id", null: false
    t.integer "participant_id", null: false
    t.json "scores", default: {}, null: false
    t.integer "total_score", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_ratings_on_participant_id"
    t.index ["round_id", "participant_id"], name: "index_ratings_on_round_id_and_participant_id", unique: true
    t.index ["round_id"], name: "index_ratings_on_round_id"
    t.check_constraint "total_score > 0", name: "positive_rating_total"
  end

  create_table "rounds", force: :cascade do |t|
    t.integer "tasting_session_id", null: false
    t.integer "number", null: false
    t.string "secret_identity", null: false
    t.string "context_info"
    t.json "tags", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tasting_session_id", "number"], name: "index_rounds_on_tasting_session_id_and_number", unique: true
    t.index ["tasting_session_id"], name: "index_rounds_on_tasting_session_id"
    t.check_constraint "number > 0", name: "positive_round_number"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tasting_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.date "date", default: -> { "CURRENT_DATE" }, null: false
    t.string "product_singular", default: "Maultasche", null: false
    t.string "product_plural", default: "Maultaschen", null: false
    t.integer "max_score_per_criterion", default: 5, null: false
    t.json "criteria_schema", default: [], null: false
    t.json "award_titles", default: {}, null: false
    t.json "vibe_messages", default: {}, null: false
    t.string "invite_token", null: false
    t.string "tv_token", null: false
    t.integer "status", default: 0, null: false
    t.boolean "entry_locked", default: false, null: false
    t.bigint "current_round_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invite_token"], name: "index_tasting_sessions_on_invite_token", unique: true
    t.index ["tv_token"], name: "index_tasting_sessions_on_tv_token", unique: true
    t.index ["user_id"], name: "index_tasting_sessions_on_user_id"
    t.check_constraint "max_score_per_criterion BETWEEN 1 AND 10", name: "valid_tasting_scale"
    t.check_constraint "status IN (0, 1, 2, 3)", name: "valid_tasting_status"
  end

  create_table "tasting_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "product_singular", null: false
    t.string "product_plural", null: false
    t.integer "max_score_per_criterion", default: 5, null: false
    t.json "criteria_schema", default: [], null: false
    t.json "award_titles", default: {}, null: false
    t.json "vibe_messages", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tasting_templates_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "participants", "tasting_sessions"
  add_foreign_key "ratings", "participants"
  add_foreign_key "ratings", "rounds"
  add_foreign_key "rounds", "tasting_sessions"
  add_foreign_key "sessions", "users"
  add_foreign_key "tasting_sessions", "rounds", column: "current_round_id", on_delete: :nullify
  add_foreign_key "tasting_sessions", "users"
end
