# frozen_string_literal: true

class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation)
    user = reservation.user
    reservation.customers.where(reminder_permission: true).each do |customer|
      if user.subscription.active? && user.social_account.line_settings_finished? && reservation.remind_customer?(customer)
        Reservations::Notifications::Reminder.run!(customer: customer, reservation: reservation)
      end
    end
  end
end
