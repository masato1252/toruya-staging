# frozen_string_literal: true

module CustomMessages
  class Demo < ActiveInteraction::Base
    object :custom_message
    object :receiver, class: User

    def execute
      case custom_message.content_type
      when CustomMessage::TEXT_TYPE
        LineClient.send(receiver.social_user, CustomMessages::ReceiverContent.run!(custom_message: custom_message, receiver: receiver, variable_source: custom_message.service))
      when CustomMessage::FLEX_TYPE
        LineClient.flex(receiver.social_user, CustomMessages::ReceiverContent.run!(custom_message: custom_message, receiver: receiver, variable_source: custom_message.service))
      end
    end
  end
end
