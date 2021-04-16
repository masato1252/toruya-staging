class AddStripeCustomerIdToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :stripe_customer_id, :string, null: true
    add_column :customers, :stripe_charge_details, :jsonb, null: true
  end
end
