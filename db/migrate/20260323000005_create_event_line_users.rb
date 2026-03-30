# frozen_string_literal: true

class CreateEventLineUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :event_line_users do |t|
      t.string :line_user_id, null: false
      t.string :display_name
      t.string :picture_url
      t.string :first_name
      t.string :last_name
      t.string :phone_number
      t.jsonb :business_types, default: [], null: false
      t.integer :business_age
      t.bigint :toruya_user_id
      t.bigint :toruya_social_user_id
      t.datetime :toruya_user_checked_at

      t.timestamps
    end

    add_index :event_line_users, :line_user_id, unique: true
    add_index :event_line_users, :toruya_user_id
    add_index :event_line_users, :toruya_social_user_id
    add_index :event_line_users, :phone_number
  end
end
