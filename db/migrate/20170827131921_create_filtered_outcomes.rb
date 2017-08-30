class CreateFilteredOutcomes < ActiveRecord::Migration[5.0]
  def change
    create_table :filtered_outcomes do |t|
      t.belongs_to :user, null: false
      t.integer :filter_id
      t.jsonb :query
      t.string :file
      t.string :aasm_state, null: false
      t.datetime :created_at
    end
  end
end
