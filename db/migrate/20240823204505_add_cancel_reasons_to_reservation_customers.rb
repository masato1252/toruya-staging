class AddCancelReasonsToReservationCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :reservation_customers, :cancel_reason, :string
  end
end
