module SocialMessages
  class Unread < ActiveInteraction::Base
    object :social_customer
    object :social_message

    def execute
      social_message.update(readed_at: nil)
      ::SocialMessages::HandleUnread.run(social_customer: social_customer, social_message: social_message)
    end
  end
end
