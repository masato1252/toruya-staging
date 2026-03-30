# frozen_string_literal: true

class CreateEventActivityLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :event_activity_logs do |t|
      t.references :event, null: false, foreign_key: true
      t.references :event_content, null: false, foreign_key: true
      t.references :event_line_user, null: false, foreign_key: true
      t.integer :activity_type, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :event_activity_logs, [:event_content_id, :activity_type], name: "idx_evt_activity_logs_content_type"
    add_index :event_activity_logs, [:event_line_user_id, :activity_type], name: "idx_evt_activity_logs_user_type"
  end
end
