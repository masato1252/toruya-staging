# frozen_string_literal: true

class CreateEventParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :event_participants do |t|
      t.references :event, null: false, foreign_key: true
      t.references :social_user, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.jsonb :business_types, default: [], null: false
      t.integer :business_age
      t.string :concern_label
      t.string :concern_category
      t.string :concern_other
      t.datetime :registered_at, null: false

      t.timestamps
    end

    add_index :event_participants, [:event_id, :social_user_id], unique: true
    add_index :event_participants, :concern_category
  end
end
