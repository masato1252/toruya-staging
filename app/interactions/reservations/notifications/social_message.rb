require "line_client"

module Reservations
  module Notifications
    class SocialMessage < ActiveInteraction::Base
      object :social_customer
      string :message

      def execute
        SocialMessages::Create.run(
          social_customer: social_customer,
          content: message,
          message_type: ::SocialMessage.message_types[:bot],
          readed: false
        )
      end
    end
  end
end
