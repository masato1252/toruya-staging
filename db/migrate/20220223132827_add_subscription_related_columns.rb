class AddSubscriptionRelatedColumns < ActiveRecord::Migration[6.0]
  def change
    add_column :online_services, :stripe_product_id, :string
    add_column :sale_pages, :recurring_prices, :jsonb
    change_column_default :sale_pages, :recurring_prices, default: {}
    add_column :online_service_customer_relations, :stripe_subscription_id, :string
  end
end
