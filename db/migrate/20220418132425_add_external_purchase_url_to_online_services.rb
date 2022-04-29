class AddExternalPurchaseUrlToOnlineServices < ActiveRecord::Migration[6.0]
  def change
    add_column :online_services, :external_purchase_url, :string
  end
end
