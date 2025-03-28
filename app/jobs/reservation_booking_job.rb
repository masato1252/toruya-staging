# frozen_string_literal: true

class ReservationBookingJob < ApplicationJob
  queue_as :high_priority

  def perform(customer, reservation, email, phone_number, booking_page, booking_options)
    # Pending reservation notification to customer
    Reservations::Notifications::Booking.run!(
      customer: customer,
      reservation: reservation,
      email: email,
      phone_number: phone_number,
      booking_page: booking_page,
      booking_options: booking_options
    )

    # Get the customer's timezone for scheduling
    Time.use_zone(customer.timezone) do
      scope = CustomMessage.scenario_of(booking_page, CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER)

      # Schedule messages for before the reservation
      scope.where.not(before_minutes: nil).each do |custom_message|
        reminder_time = reservation.start_time.in_time_zone(customer_timezone).advance(minutes: -custom_message.before_minutes)

        Notifiers::Customers::CustomMessages::ReservationReminder.perform_at(
          schedule_at: reminder_time,
          custom_message: custom_message,
          reservation: reservation,
          receiver: customer
        )
      end

      # Schedule messages for after the reservation
      scope.where.not(after_days: nil).each do |custom_message|
        reminder_time = reservation.start_time.in_time_zone(customer_timezone).advance(days: custom_message.after_days)

        Notifiers::Customers::CustomMessages::ReservationReminder.perform_at(
          schedule_at: reminder_time,
          custom_message: custom_message,
          reservation: reservation,
          receiver: customer
        )
      end
    end
  end
end
