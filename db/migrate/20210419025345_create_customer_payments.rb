class CreateCustomerPayments < ActiveRecord::Migration[5.2]
  def change
    create_table :customer_payments do |t|
      t.references :customer
      t.decimal :amount_cents
      t.string :amount_currency
      t.integer :product_id, null: true
      t.string :product_type, null: true
      t.integer :state, default: 0, null: false
      t.datetime :charge_at
      t.datetime :expired_at
      t.boolean :manual, default: false, null: false
      t.jsonb :stripe_charge_details
      t.string :order_id

      t.timestamps
    end

    add_index :customer_payments, [:product_id, :product_type]
  end
end
