class CreateSurveyActivities < ActiveRecord::Migration[6.1]
  def change
    create_table :survey_activities do |t|
      t.references :survey_question, null: false
      t.references :survey, null: false
      t.string :name, null: false
      t.integer :position
      t.integer :max_participants
      t.integer :price_cents
      t.string :currency
      t.timestamps
    end

    create_table :survey_activity_slots do |t|
      t.references :survey_activity, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.timestamps
    end

    add_column :surveys, :slug, :string
    add_index :surveys, :slug, unique: true
    add_column :surveys, :deleted_at, :datetime

    add_column :survey_responses, :survey_activity_id, :integer
    add_index :survey_responses, [:survey_activity_id, :owner_type, :owner_id],
              unique: true,
              name: 'idx_survey_responses_on_activity_and_owner'
    add_column :survey_responses, :uuid, :string
    add_index :survey_responses, [:uuid], unique: true
    add_column :survey_responses, :state, :integer, default: 0

    add_reference :question_answers, :survey_activity

    add_column :reservations, :survey_activity_id, :integer
    add_column :reservations, :survey_activity_slot_id, :integer
    add_index :reservations, [:survey_activity_id, :survey_activity_slot_id],
              name: 'idx_reservations_on_activity_and_slot'

    add_column :reservation_customers, :survey_activity_id, :integer
    add_index :reservation_customers, :survey_activity_id
  end
end
