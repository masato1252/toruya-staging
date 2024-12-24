class AllowSalePageNilOnlineServiceCustomerRelations < ActiveRecord::Migration[7.0]
  def change
    change_column_null :online_service_customer_relations, :sale_page_id, true
  end
end
