# frozen_string_literal: true

module Events
  class NotifyWaitlist < ActiveInteraction::Base
    object :consultation

    def execute
      event_content = consultation.event_content
      event_line_user = consultation.event_line_user
      return unless event_line_user

      message = "Toruyaイベント『#{event_content.title}』参加者限定でご提供する無料相談会のキャンセル待ちを承りました。\n\nイベント終了後のご案内をお待ちください。"

      send_line_message(event_line_user.line_user_id, message)
    rescue => e
      Rollbar.error(e, "Failed to send waitlist notification", consultation_id: consultation.id)
    end

    private

    def send_line_message(line_user_id, message)
      client = UserBotSocialAccount.client
      client.push_message(line_user_id, { type: "text", text: message })
    rescue => e
      Rails.logger.error("[NotifyWaitlist] LINE message send failed: #{e.class} #{e.message}")
    end
  end
end
