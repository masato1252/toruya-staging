# frozen_string_literal: true

class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation)
    reservation.customers.where(reminder_permission: true).each do |customer|
      Reservations::Notifications::Reminder.run!(customer: customer, reservation: reservation)
    end
  end
end
