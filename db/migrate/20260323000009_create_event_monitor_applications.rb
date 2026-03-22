# frozen_string_literal: true

class CreateEventMonitorApplications < ActiveRecord::Migration[7.0]
  def change
    create_table :event_monitor_applications do |t|
      t.references :event_content, null: false, foreign_key: true
      t.references :social_user, null: false, foreign_key: true
      t.integer :customer_id

      t.timestamps
    end

    add_index :event_monitor_applications, [:event_content_id, :social_user_id], unique: true, name: "idx_evt_monitor_apps_unique"
  end
end
