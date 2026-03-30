# frozen_string_literal: true

class CreateEventUpsellConsultations < ActiveRecord::Migration[7.0]
  def change
    create_table :event_upsell_consultations do |t|
      t.references :event_content, null: false, foreign_key: true
      t.references :event_line_user, null: false, foreign_key: true
      t.integer :customer_id
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :event_upsell_consultations, [:event_content_id, :event_line_user_id], unique: true, name: "idx_evt_upsell_consults_unique"
    add_index :event_upsell_consultations, :status
  end
end
