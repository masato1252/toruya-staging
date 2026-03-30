# frozen_string_literal: true

class CreateEventParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :event_participants do |t|
      t.references :event, null: false, foreign_key: true
      t.references :event_line_user, null: false, foreign_key: true
      t.jsonb :business_types, default: [], null: false
      t.integer :business_age
      t.jsonb :concern_labels, default: [], null: false
      t.string :concern_other
      t.datetime :registered_at, null: false

      t.timestamps
    end

    add_index :event_participants, [:event_id, :event_line_user_id], unique: true
  end
end
