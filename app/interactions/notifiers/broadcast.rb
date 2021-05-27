# frozen_string_literal: true

require "translator"

module Notifiers
  class Broadcast < Base
    deliver_by :line
    object :broadcast

    def message
      Translator.perform(broadcast.content, { customer_name: receiver.display_last_name })
    end

    def send_line
      SocialMessages::Create.run(
        social_customer: target_line_user,
        content: message,
        message_type: SocialMessage.message_types[:bot],
        readed: true,
        broadcast: broadcast
      )
    end
  end
end
