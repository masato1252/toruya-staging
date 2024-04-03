class AddProviderToCustomerPayments < ActiveRecord::Migration[7.0]
  def change
    add_column :customer_payments, :provider, :string, default: AccessProvider.providers[:stripe_connect]
  end
end
