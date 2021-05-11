# frozen_string_literal: true

module SocialMessages
  class Recent < ActiveInteraction::Base
    MESSAGES_PER_PAGE = 50

    object :customer

    def execute
      scope = SocialMessage.includes(:social_customer).where.not(message_type: SocialMessage.message_types[:customer_reply_bot]).where(social_customers: { social_user_id: customer.social_customer.social_user_id })
      social_messages =
        scope
        .where(
          "social_messages.created_at < :oldest_message_at OR
        (social_messages.created_at = :oldest_message_at AND social_messages.id < :oldest_message_id)",
        oldest_message_at: Time.current,
        oldest_message_id: INTEGER_MAX)
        .ordered
        .limit(MESSAGES_PER_PAGE + 1)

      scope.where(readed_at: nil).update_all(readed_at: Time.current)

      UserBotLines::Actions::SwitchRichMenu.run(
        social_user: customer.user.social_user,
        rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY
      )

      _messages = social_messages[0...MESSAGES_PER_PAGE].map { |message| MessageSerializer.new(message).attributes_hash }
      _messages.reverse!
    end
  end
end
