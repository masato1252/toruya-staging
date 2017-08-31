class CreateFilteredOutcomes < ActiveRecord::Migration[5.0]
  def change
    create_table :filtered_outcomes do |t|
      t.belongs_to :user, null: false
      t.integer :filter_id
      t.jsonb :query
      t.string :file
      t.string :page_size
      t.string :outcome_type
      t.string :aasm_state, null: false
      t.datetime :created_at
    end

    add_index :filtered_outcomes, [:user_id, :aasm_state, :created_at], name: :filtered_outcome_index
  end
end
