class AddErrorMessageToSubscriptionCharges < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_charges, :error_message, :text
  end
end
