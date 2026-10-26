class CreateTastingDomain < ActiveRecord::Migration[8.1]
  def change
    create_table :tasting_templates do |t|
      t.string :name, null: false
      t.string :product_singular, null: false
      t.string :product_plural, null: false
      t.integer :max_score_per_criterion, null: false, default: 5
      t.json :criteria_schema, null: false, default: []
      t.json :award_titles, null: false, default: {}
      t.json :vibe_messages, null: false, default: {}
      t.timestamps
    end
    add_index :tasting_templates, :name, unique: true
    create_table :tasting_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.date :date, null: false, default: -> { "CURRENT_DATE" }
      t.string :product_singular, null: false, default: "Maultasche"
      t.string :product_plural, null: false, default: "Maultaschen"
      t.integer :max_score_per_criterion, null: false, default: 5
      t.json :criteria_schema, null: false, default: []
      t.json :award_titles, null: false, default: {}
      t.json :vibe_messages, null: false, default: {}
      t.string :invite_token, null: false
      t.string :tv_token, null: false
      t.integer :status, null: false, default: 0
      t.boolean :entry_locked, null: false, default: false
      t.bigint :current_round_id
      t.timestamps
    end
    add_index :tasting_sessions, :invite_token, unique: true
    add_index :tasting_sessions, :tv_token, unique: true
    add_check_constraint :tasting_sessions, "status IN (0, 1, 2, 3)", name: "valid_tasting_status"
    add_check_constraint :tasting_sessions, "max_score_per_criterion BETWEEN 1 AND 10", name: "valid_tasting_scale"
    create_table :rounds do |t|
      t.references :tasting_session, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :secret_identity, null: false
      t.string :context_info
      t.json :tags, null: false, default: []
      t.timestamps
    end
    add_index :rounds, [ :tasting_session_id, :number ], unique: true
    add_check_constraint :rounds, "number > 0", name: "positive_round_number"
    add_foreign_key :tasting_sessions, :rounds, column: :current_round_id
    create_table :participants do |t|
      t.references :tasting_session, null: false, foreign_key: true
      t.string :name, null: false, limit: 25
      t.string :session_token, null: false
      t.boolean :blocked, null: false, default: false
      t.timestamps
    end
    add_index :participants, :session_token, unique: true
    create_table :ratings do |t|
      t.references :round, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.json :scores, null: false, default: {}
      t.integer :total_score, null: false
      t.text :notes
      t.timestamps
    end
    add_index :ratings, [ :round_id, :participant_id ], unique: true
    add_check_constraint :ratings, "total_score > 0", name: "positive_rating_total"
  end
end
