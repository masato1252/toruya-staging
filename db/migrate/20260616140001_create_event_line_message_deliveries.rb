# frozen_string_literal: true

class CreateEventLineMessageDeliveries < ActiveRecord::Migration[7.0]
  def change
    create_table :event_line_message_deliveries do |t|
      t.references :event_line_message_setting, null: false, foreign_key: true, index: { name: "idx_event_line_msg_deliveries_setting_id" }
      t.references :event_line_user, null: false, foreign_key: true, index: { name: "idx_event_line_msg_deliveries_line_user_id" }
      t.datetime :sent_at
      t.text :error_message

      t.timestamps
    end

    add_index :event_line_message_deliveries,
              [:event_line_message_setting_id, :event_line_user_id],
              unique: true,
              name: "idx_event_line_msg_deliveries_unique_user"
  end
end
