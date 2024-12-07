class AddCustomerTicketsQuotaToReservationCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :reservation_customers, :customer_tickets_quota, :jsonb, default: {}

    ReservationCustomer.where.not(customer_ticket_id: nil).each do |reservation_customer|
      reservation_customer.update!(customer_tickets_quota: {
        reservation_customer.customer_ticket_id => {
          nth_quota: reservation_customer.nth_quota,
          product_id: reservation_customer.booking_option_id
        }
      })
    end
  end
end
