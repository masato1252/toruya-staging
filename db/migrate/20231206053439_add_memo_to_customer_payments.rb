class AddMemoToCustomerPayments < ActiveRecord::Migration[7.0]
  def change
    add_column :customer_payments, :memo, :string
  end
end
