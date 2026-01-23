# frozen_string_literal: true

require "translator"

module Notifiers
  module Customers
    module CustomMessages
      class ReservationReminder < Base
        object :custom_message
        object :reservation

        validate :receiver_should_be_customer
        validate :service_should_be_booking_page_or_shop

        def message
          compose(::CustomMessages::ReceiverContent, custom_message: custom_message, receiver: receiver, variable_source: reservation)
        end

  def deliverable
    result = if custom_message.after_days
      reservation.reminderable? && expected_schedule_time && reservation.remind_customer?(receiver)
    else
      expected_schedule_time && reservation.remind_customer?(receiver)
    end
    
    Rails.logger.info "[ReservationReminder] ===== カスタムリマインド実行チェック ====="
    Rails.logger.info "[ReservationReminder] reservation_id: #{reservation.id}, receiver_id: #{receiver.id}"
    Rails.logger.info "[ReservationReminder] custom_message: #{custom_message.scenario} (#{custom_message.before_minutes ? "#{custom_message.before_minutes}分前" : "#{custom_message.after_days}日後"})"
    Rails.logger.info "[ReservationReminder] deliverable?: #{result}"
    if !result
      Rails.logger.info "[ReservationReminder]   - reminderable?: #{reservation.reminderable?}" if custom_message.after_days
      Rails.logger.info "[ReservationReminder]   - expected_schedule_time?: #{expected_schedule_time}"
      Rails.logger.info "[ReservationReminder]   - remind_customer?: #{reservation.remind_customer?(receiver)}"
    end
    
    result
  end

        private

        def expected_schedule_time
          if schedule_at && custom_message.before_minutes
            expected_schedule_at = reservation.start_time.advance(minutes: -custom_message.before_minutes)
            return expected_schedule_at.utc.to_i == schedule_at.utc.to_i
          elsif schedule_at && custom_message.after_days
            expected_schedule_at = reservation.start_time.advance(days: custom_message.after_days)
            return expected_schedule_at.utc.to_i == schedule_at.utc.to_i
          end

          true # real time
        end

        def service_should_be_booking_page_or_shop
          unless custom_message.service.is_a?(BookingPage) || custom_message.service.is_a?(Shop)
            errors.add(:custom_message, :is_invalid_service)
          end
        end
      end
    end
  end
end
