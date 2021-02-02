# frozen_string_literal: true

class ChangeLineUserRequiredColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_codes, :user_id, :integer
    add_column :users, :phone_number, :string
    add_column :profiles, :email, :string
    add_column :profiles, :region, :string
    add_column :profiles, :city, :string
    add_column :profiles, :street1, :string
    add_column :profiles, :street2, :string
    add_column :staff_accounts, :phone_number, :string
    change_column_null :notifications, :user_id, true
    change_column_null :users, :email, true
    change_column_null :staff_accounts, :email, true
    change_column_default :users, :email, nil

    add_index :users, :phone_number, unique: true
    add_index :staff_accounts, [:owner_id, :phone_number], unique: true
  end
end
