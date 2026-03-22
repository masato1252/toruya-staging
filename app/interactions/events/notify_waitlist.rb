# frozen_string_literal: true

module Events
  class NotifyWaitlist < ActiveInteraction::Base
    object :consultation

    def execute
      event_content = consultation.event_content
      event = event_content.event
      social_user = consultation.social_user

      social_customer = find_social_customer(event, social_user)
      return unless social_customer

      message = "ToruyaランサーマッチングEXPO『#{event_content.title}』参加者限定でご提供する無料相談会のキャンセル待ちを承りました。\n\nイベント終了後のご案内を待ちください。"

      LineClient.send(social_customer, message)
    rescue => e
      Rollbar.error(e, "Failed to send waitlist notification", consultation_id: consultation.id)
    end

    private

    def find_social_customer(event, social_user)
      event.user.social_customers.find_by(social_user_id: social_user.social_service_user_id)
    end
  end
end
