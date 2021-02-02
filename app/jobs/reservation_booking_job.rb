# frozen_string_literal: true

class ReservationBookingJob < ApplicationJob
  queue_as :default

  def perform(customer, reservation, email, phone_number, booking_page, booking_option)
    Reservations::Notifications::Booking.run!(
      customer: customer,
      reservation: reservation,
      email: email,
      phone_number: phone_number,
      booking_page: booking_page,
      booking_option: booking_option
    )
  end
end
