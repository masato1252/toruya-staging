# frozen_string_literal: true

module Events
  class NotifyMonitorApplication < ActiveInteraction::Base
    object :application

    def execute
      event_content = application.event_content
      event_line_user = application.event_line_user
      return unless event_line_user

      message = "Toruyaイベント『#{event_content.title}』参加者限定でご提供するモニターへのご応募を承りました。\n\nモニター当選者には、イベント終了後にご案内させていただきますので、それまでお待ちください。"

      send_line_message(event_line_user.line_user_id, message)
    rescue => e
      Rollbar.error(e, "Failed to send monitor application notification", application_id: application.id)
    end

    private

    def send_line_message(line_user_id, message)
      client = UserBotSocialAccount.client
      client.push_message(line_user_id, { type: "text", text: message })
    rescue => e
      Rails.logger.error("[NotifyMonitorApplication] LINE message send failed: #{e.class} #{e.message}")
    end
  end
end
