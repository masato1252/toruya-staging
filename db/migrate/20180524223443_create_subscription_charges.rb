class CreateSubscriptionCharges < ActiveRecord::Migration[5.1]
  def change
    create_table :subscription_charges do |t|
      t.references :user
      t.references :plan
      t.decimal :amount_cents
      t.string :amount_currency
      t.integer :state
      t.date :charge_date
      t.boolean :manual, default: false, null: false
      t.jsonb :stripe_charge_details
      t.string :order_id
      t.timestamps
    end

    add_index :subscription_charges, :order_id, name: :order_id_index
  end
end
