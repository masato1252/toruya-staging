class AddDefaultPaymentToAccessProviderAndBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :access_providers, :default_payment, :boolean, default: false
    add_column :booking_pages, :default_provider, :string

    AccessProvider.where(provider: "stripe_connect").update_all(default_payment: true)
  end
end
