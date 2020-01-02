class CreatePaymentWithdrawals < ActiveRecord::Migration[5.2]
  def change
    create_table :payment_withdrawals do |t|
      t.integer :receiver_id, null: false
      t.integer :state, null: false, default: 0
      t.decimal :amount_cents, null: false
      t.string :amount_currency, null: false
      t.string :order_id
      t.jsonb :details

      t.timestamps
    end

    add_index :payment_withdrawals, [:receiver_id, :state, :amount_cents, :amount_currency], name: :payment_withdrawal_receiver_state_index
    add_index :payment_withdrawals, [:order_id], name: :payment_withdrawal_order_index, unique: true
  end
end
