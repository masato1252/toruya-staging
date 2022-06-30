class AddSubscriptionToBundledServices < ActiveRecord::Migration[6.0]
  def change
    add_column :bundled_services, :subscription, :boolean
    change_column_default :bundled_services, :subscription, false
    add_column :online_service_customer_relations, :bundled_service_id, :integer
  end
end
