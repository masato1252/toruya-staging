# frozen_string_literal: true

class CreateEventLineMessageBroadcastDeliveries < ActiveRecord::Migration[7.0]
  def change
    create_table :event_line_message_broadcast_deliveries do |t|
      t.references :event_line_message_broadcast, null: false, foreign_key: true, index: { name: "idx_event_line_msg_broadcast_deliveries_broadcast" }
      t.references :event_line_user, null: false, foreign_key: true, index: { name: "idx_event_line_msg_broadcast_deliveries_line_user" }
      t.datetime :sent_at
      t.text :error_message

      t.timestamps
    end

    add_index :event_line_message_broadcast_deliveries,
              [:event_line_message_broadcast_id, :event_line_user_id],
              unique: true,
              name: "idx_event_line_msg_broadcast_deliveries_unique_user"
  end
end
