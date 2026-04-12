# frozen_string_literal: true

class CreateEventStampEntries < ActiveRecord::Migration[6.1]
  def change
    create_table :event_stamp_entries do |t|
      t.references :event, null: false, foreign_key: true
      t.references :event_content, null: false, foreign_key: true
      t.references :event_line_user, null: false, foreign_key: true
      t.integer :action_type, null: false

      t.timestamps
    end

    add_index :event_stamp_entries,
              [:event_line_user_id, :event_content_id, :action_type],
              unique: true,
              name: "idx_stamp_entries_unique_action"
  end
end
