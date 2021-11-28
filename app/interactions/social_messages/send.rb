require "line_client"

module SocialMessages
  class Send < ActiveInteraction::Base
    object :social_message

    def execute
      response = LineClient.send(social_message.social_customer, social_message.raw_content)

      if response&.code == "200" || Rails.env.test?
        social_message.update(sent_at: Time.current)
      else
        Rollbar.error(
          "Line send message failed",
          user_id: social_message.social_customer.user_id,
          social_message_id: social_message.id,
          response: response.body
        )

        raise ActiveRecord::Rollback
      end
    end
  end
end
