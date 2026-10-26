class NullifyCurrentRoundOnDelete < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :tasting_sessions, column: :current_round_id
    add_foreign_key :tasting_sessions, :rounds, column: :current_round_id, on_delete: :nullify
  end
end
