require "line_client"

module SocialMessages
  class Send < ActiveInteraction::Base
    object :social_message

    def execute
      response = LineClient.send(social_message.social_customer, social_message.raw_content)

      if response&.code == "200"
        social_message.update(sent_at: Time.current)
      else
        raise ActiveRecord::Rollback
      end
    end
  end
end
