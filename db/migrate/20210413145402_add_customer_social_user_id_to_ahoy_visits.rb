class AddCustomerSocialUserIdToAhoyVisits < ActiveRecord::Migration[5.2]
  def change
    add_column :ahoy_visits, :customer_social_user_id, :string, null: true
    add_index :ahoy_visits, :customer_social_user_id
  end
end
