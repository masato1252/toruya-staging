# frozen_string_literal: true

module CustomMessages
  class Demo < ActiveInteraction::Base
    object :custom_message
    object :receiver, class: User

    def execute
      case custom_message.content_type
      when CustomMessage::TEXT_TYPE
        if receiver.customer_notification_channel == "line" || receiver.fallback_email.nil?
          LineClient.send(receiver.social_user, message_content)
        else
          UserMailer.with(
            email: receiver.fallback_email,
            message: message_content,
            subject: I18n.t("user_mailer.custom.title")
          ).custom.deliver_now
        end
      when CustomMessage::FLEX_TYPE
        LineClient.flex(receiver.social_user, message_content)
      end
    end

    private

    def message_content
      CustomMessages::ReceiverContent.run!(custom_message: custom_message, receiver: receiver, variable_source: custom_message.service)
    end
  end
end
