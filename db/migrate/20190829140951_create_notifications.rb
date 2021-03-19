# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[5.2]
  def change
    create_table :notifications do |t|
      t.integer :user_id, null: false
      t.string :phone_number
      t.text :content
      t.integer :customer_id
      t.integer :reservation_id
      t.boolean :charged, default: false

      t.timestamps
    end

    add_index :notifications, [:user_id, :charged]
  end
end
