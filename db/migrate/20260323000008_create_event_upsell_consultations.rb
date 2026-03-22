# frozen_string_literal: true

class CreateEventUpsellConsultations < ActiveRecord::Migration[7.0]
  def change
    create_table :event_upsell_consultations do |t|
      t.references :event_content, null: false, foreign_key: true
      t.references :social_user, null: false, foreign_key: true
      t.integer :customer_id
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :event_upsell_consultations, [:event_content_id, :social_user_id], unique: true
    add_index :event_upsell_consultations, :status
  end
end
