# frozen_string_literal: true

module SocialMessages
  class Recent < ActiveInteraction::Base
    MESSAGES_PER_PAGE = 10
    object :customer
    time :oldest_message_at, default: nil
    integer :oldest_message_id, default: nil

    def execute
      scope = SocialMessage.includes(:social_customer, :staff).legal.where.not(message_type: SocialMessage.message_types[:customer_reply_bot]).where(user_id: customer.user_id, customer_id: customer.id)
      social_messages =
        scope
        .where(
          "social_messages.created_at < :oldest_message_at OR
        (social_messages.created_at = :oldest_message_at AND social_messages.id < :oldest_message_id)",
        oldest_message_at: oldest_message_at || Time.current,
        oldest_message_id: oldest_message_id || INTEGER_MAX)
        .where("social_messages.created_at > ?", Time.current.advance(months: -6))
        .ordered
        .limit(MESSAGES_PER_PAGE + 1)

      scope.where(readed_at: nil).update_all(readed_at: Time.current)

      UserBotLines::Actions::SwitchRichMenu.run(social_user: customer.user.social_user)

      _messages = social_messages[0...MESSAGES_PER_PAGE].map { |message| MessageSerializer.new(message).attributes_hash }

      {
        messages: _messages.reverse!,
        has_more_messages: social_messages.size > MESSAGES_PER_PAGE
      }
    end
  end
end
