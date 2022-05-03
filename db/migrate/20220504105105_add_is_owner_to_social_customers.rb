class AddIsOwnerToSocialCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :social_customers, :is_owner, :boolean
    change_column_default :social_customers, :is_owner, false
  end
end
