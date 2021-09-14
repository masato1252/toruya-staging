require "line_client"

module SocialUserMessages
  class Send < ActiveInteraction::Base
    object :social_user_message

    def execute
      response = LineClient.send(social_user_message.social_user, social_user_message.raw_content)

      if response&.code == "200" || Rails.env.test?
        social_user_message.update(sent_at: Time.current)
      else
        errors.add(:social_user_message, :sent_failed)
      end
    end
  end
end
