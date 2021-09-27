class AddPaymentStateToReservationCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :reservation_customers, :payment_state, :integer
    change_column_default :reservation_customers, :payment_state, 0

    ReservationCustomer.update_all(payment_state: 0)
  end
end
