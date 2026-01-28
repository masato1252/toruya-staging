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
    # 重複送信チェック：過去30分以内に同じリマインダーが送信されていないか確認
    already_sent = check_duplicate_delivery
    
    result = if already_sent
      false
    elsif custom_message.after_days
      reservation.reminderable? && expected_schedule_time && reservation.remind_customer?(receiver)
    else
      expected_schedule_time && reservation.remind_customer?(receiver)
    end
    
    Rails.logger.info "[ReservationReminder] ===== カスタムリマインド実行チェック ====="
    Rails.logger.info "[ReservationReminder] reservation_id: #{reservation.id}, receiver_id: #{receiver.id}"
    Rails.logger.info "[ReservationReminder] custom_message: #{custom_message.scenario} (#{custom_message.before_minutes ? "#{custom_message.before_minutes}分前" : "#{custom_message.after_days}日後"})"
    Rails.logger.info "[ReservationReminder] already_sent?: #{already_sent}"
    Rails.logger.info "[ReservationReminder] deliverable?: #{result}"
    if !result && !already_sent
      Rails.logger.info "[ReservationReminder]   - reminderable?: #{reservation.reminderable?}" if custom_message.after_days
      Rails.logger.info "[ReservationReminder]   - expected_schedule_time?: #{expected_schedule_time}"
      Rails.logger.info "[ReservationReminder]   - remind_customer?: #{reservation.remind_customer?(receiver)}"
    end
    
    result
  end

        private

        def check_duplicate_delivery
          # 過去30分以内に同じ予約・同じ顧客・同じカスタムメッセージが送信されているかチェック
          time_window = 30.minutes.ago
          
          SocialMessage.where(
            customer_id: receiver.id,
            user_id: reservation.user_id,
            channel: 'email', # メールのみ対象
            custom_message_id: custom_message.id, # 同じカスタムメッセージで区別
            reservation_id: reservation.id # 同じ予約で区別
          ).where("created_at >= ?", time_window)
           .exists?
        end

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
