class AddFunctionAccessIdToOnlineServiceCustomerRelations < ActiveRecord::Migration[6.1]
  def change
    add_column :online_service_customer_relations, :function_access_id, :bigint
  end
end 