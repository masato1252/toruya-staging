# frozen_string_literal: true

# Remind customer
class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation)
    user = reservation.user

    reservation.customers.each do |customer|
      # 重複送信チェック：過去2時間以内に同じリマインダーが送信されていないか確認
      already_sent = ::SocialMessage.where(
        customer_id: customer.id,
        user_id: reservation.user_id,
        channel: 'email',
        reservation_id: reservation.id
      ).where("created_at >= ?", Time.current - 2.hours)
       .exists?

      if already_sent
        Rails.logger.info "[ReservationReminderJob] Skip: reservation_id=#{reservation.id}, customer_id=#{customer.id} - Already sent within 2 hours"
        next
      end

      if user.subscription.active? && reservation.remind_customer?(customer)
        Reservations::Notifications::Reminder.run!(customer: customer, reservation: reservation)
      end
    end
  end
end
