class AddBookingOptionIdsToReservationCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :reservation_customers, :booking_option_ids, :jsonb, default: []

    ReservationCustomer.where.not(booking_option_id: nil).find_each do |reservation_customer|
      reservation_customer.update(booking_option_ids: [reservation_customer.booking_option_id])
    end
  end
end
