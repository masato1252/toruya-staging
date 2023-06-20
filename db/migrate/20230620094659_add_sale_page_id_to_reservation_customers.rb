class AddSalePageIdToReservationCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :reservation_customers, :sale_page_id, :integer
    add_index :reservation_customers, [:sale_page_id, :created_at]
  end
end
