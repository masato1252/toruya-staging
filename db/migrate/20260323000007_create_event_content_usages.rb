# frozen_string_literal: true

class CreateEventContentUsages < ActiveRecord::Migration[7.0]
  def change
    create_table :event_content_usages do |t|
      t.references :event_content, null: false, foreign_key: true
      t.references :social_user, null: false, foreign_key: true
      t.datetime :started_at, null: false

      t.timestamps
    end

    add_index :event_content_usages, [:event_content_id, :social_user_id], unique: true
  end
end
