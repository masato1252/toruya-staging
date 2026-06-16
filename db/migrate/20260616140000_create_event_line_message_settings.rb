# frozen_string_literal: true

class CreateEventLineMessageSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :event_line_message_settings do |t|
      t.references :event, null: false, foreign_key: true
      t.boolean :enabled, null: false, default: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.text :message, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :event_line_message_settings, [:event_id, :position]
    add_index :event_line_message_settings, [:event_id, :enabled, :starts_at], name: "idx_event_line_msg_settings_active_window"
  end
end
