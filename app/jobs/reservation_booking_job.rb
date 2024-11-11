# frozen_string_literal: true

class ReservationBookingJob < ApplicationJob
  queue_as :default

  def perform(customer, reservation, email, phone_number, booking_page, booking_options)
    Reservations::Notifications::Booking.run!(
      customer: customer,
      reservation: reservation,
      email: email,
      phone_number: phone_number,
      booking_page: booking_page,
      booking_options: booking_options
    )

    scope = CustomMessage.scenario_of(booking_page, CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER)
    scope.where.not(before_minutes: nil).each do |custom_message|
      Notifiers::Customers::CustomMessages::ReservationReminder.perform_at(
        schedule_at: reservation.start_time.advance(minutes: -custom_message.before_minutes),
        custom_message: custom_message,
        reservation: reservation,
        receiver: customer
      )
    end

    scope.where.not(after_days: nil).each do |custom_message|
      Notifiers::Customers::CustomMessages::ReservationReminder.perform_at(
        schedule_at: reservation.start_time.advance(days: custom_message.after_days),
        custom_message: custom_message,
        reservation: reservation,
        receiver: customer
      )
    end
  end
end
