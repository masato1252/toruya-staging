# frozen_string_literal: true

module Events
  class SendLineLoginMessages < ActiveInteraction::Base
    object :event
    object :event_line_user
    time :now, default: -> { Time.current }

    def execute
      settings = event.event_line_message_settings.active_at(now).ordered
      settings.each do |setting|
        deliver_setting(setting)
      end
    end

    private

    def deliver_setting(setting)
      delivery = setting.event_line_message_deliveries.find_or_initialize_by(event_line_user: event_line_user)
      return if delivery.sent_at.present?

      send_line_message(setting.message)
      delivery.assign_attributes(sent_at: Time.current, error_message: nil)
      delivery.save!
    rescue StandardError => e
      persist_delivery_error(delivery, e) if defined?(delivery) && delivery
      Rollbar.error(e, "Failed to send event LINE login message", event_id: event.id, event_line_user_id: event_line_user.id, setting_id: setting.id)
    end

    def send_line_message(message)
      UserBotSocialAccount.client.push_message(
        event_line_user.line_user_id,
        { type: "text", text: message }
      )
    end

    def persist_delivery_error(delivery, exception)
      delivery.error_message = "#{exception.class}: #{exception.message}".truncate(1000)
      delivery.save! if delivery.persisted? || delivery.event_line_user_id.present?
    rescue StandardError => e
      Rails.logger.error("[SendLineLoginMessages] Failed to persist delivery error: #{e.class} #{e.message}")
    end
  end
end
