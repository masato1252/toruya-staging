class AddCustomerUpdatedToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :customer_latest_activity_at, :datetime

    add_index :users, :customer_latest_activity_at
  end
end
