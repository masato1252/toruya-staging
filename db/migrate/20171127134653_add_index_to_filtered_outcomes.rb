# frozen_string_literal: true

class AddIndexToFilteredOutcomes < ActiveRecord::Migration[5.1]
  def change
    remove_index :filtered_outcomes, name: :filtered_outcome_index
    add_index :filtered_outcomes, [:user_id, :aasm_state, :outcome_type, :created_at], name: :filtered_outcome_index
  end
end
