class AddFunctionAccessIdToReservationCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :reservation_customers, :function_access_id, :bigint
  end
end 