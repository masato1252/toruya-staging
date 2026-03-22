# frozen_string_literal: true

module Events
  class NotifyMonitorApplication < ActiveInteraction::Base
    object :application

    def execute
      event_content = application.event_content
      event = event_content.event
      social_user = application.social_user

      social_customer = find_social_customer(event, social_user)
      return unless social_customer

      message = "ToruyaランサーマッチングEXPO『#{event_content.title}』参加者限定でご提供するモニターへのご応募を承りました。\n\nモニター当選者には、イベント終了後にご案内させていただきますので、それまで待ちください。"

      LineClient.send(social_customer, message)
    rescue => e
      Rollbar.error(e, "Failed to send monitor application notification", application_id: application.id)
    end

    private

    def find_social_customer(event, social_user)
      event.user.social_customers.find_by(social_user_id: social_user.social_service_user_id)
    end
  end
end
