# frozen_string_literal: true

# Remind customer
class ReservationReminderJob < ApplicationJob
  queue_as :default

  def perform(reservation)
    user = reservation.user

    # 24時間前リマインダー用のCustomMessageを取得
    custom_message = CustomMessage.find_by(
      service_type: "Shop",
      service_id: reservation.shop_id,
      scenario: "reservation_one_day_reminder",
      after_days: nil
    )
    custom_message_id = custom_message&.id

    reservation.customers.each do |customer|
      # 重複送信チェック：過去2時間以内に同じリマインダーが送信されていないか確認
      # custom_message_idも条件に含める
      already_sent = ::SocialMessage.where(
        customer_id: customer.id,
        user_id: reservation.user_id,
        channel: 'email',
        reservation_id: reservation.id,
        custom_message_id: custom_message_id  # custom_message_idで絞り込み（nilも含む）
      ).where("created_at >= ?", Time.current - 2.hours)
       .exists?

      if already_sent
        Rails.logger.info "[ReservationReminderJob] Skip: reservation_id=#{reservation.id}, customer_id=#{customer.id}, custom_message_id=#{custom_message_id} - Already sent within 2 hours"
        next
      end

      if user.subscription.active? && reservation.remind_customer?(customer)
        Reservations::Notifications::Reminder.run!(customer: customer, reservation: reservation)
      end
    end
  end
end
