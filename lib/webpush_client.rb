# frozen_string_literal: true

require "webpush"

class WebpushClient
  attr_reader :subscription

  def self.send(subscription:, message:)
    Webpush.payload_send(
      message: message.to_json,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh_key,
      auth: subscription.auth_key,
      ttl: 24 * 60 * 60,
      vapid: {
        subject: "mailto:#{User::ADMIN_EMAIL}",
        public_key: Rails.application.secrets.web_push_public_key,
        private_key: Rails.application.secrets.web_push_private_key
      }
    )
  end
end
