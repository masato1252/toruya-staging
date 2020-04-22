module Bookings
  class CustomerSmsNotificationJob < ApplicationJob
    queue_as :default

    def perform(customer, reservation, phone_number)
      Reservations::Notifications::SendCustomerSms.run!(
        phone_number: phone_number,
        customer: customer,
        reservation: reservation,
        message: reservation.reservation_customers.find_by(customer: customer).sms_booking_message
      )
    end
  end
end
