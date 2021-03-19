# frozen_string_literal: true

class CreatePayments < ActiveRecord::Migration[5.2]
  def change
    create_table :payments do |t|
      t.integer :receiver_id, null: false
      t.integer :referrer_id
      t.integer :payment_withdrawal_id
      t.integer :charge_id
      t.decimal :amount_cents, null: false
      t.string :amount_currency, null: false
      t.jsonb :details

      t.timestamps
    end

    add_index :payments, [:receiver_id], name: :payment_receiver_index
  end
end
