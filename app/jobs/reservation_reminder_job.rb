# frozen_string_literal: true

# Remind customer
class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation)
    user = reservation.user

    reservation.customers.each do |customer|
      if user.subscription.active? && reservation.remind_customer?(customer)
        Reservations::Notifications::Reminder.run!(customer: customer, reservation: reservation)
      end
    end
  end
end
