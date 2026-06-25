# frozen_string_literal: true

class CreateEventLineMessageBroadcasts < ActiveRecord::Migration[7.0]
  def change
    create_table :event_line_message_broadcasts do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at
      t.text :message, null: false
      t.integer :delivered_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0

      t.timestamps
    end

    add_index :event_line_message_broadcasts, [:event_id, :scheduled_at], name: "idx_event_line_msg_broadcasts_schedule"
    add_index :event_line_message_broadcasts, [:status, :scheduled_at], name: "idx_event_line_msg_broadcasts_status_schedule"
  end
end
