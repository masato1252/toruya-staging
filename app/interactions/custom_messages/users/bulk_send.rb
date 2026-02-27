# frozen_string_literal: true

module CustomMessages
  module Users
    class BulkSend < ActiveInteraction::Base
      string :content
      array :user_ids
      string :scenario

      def execute
        success_count = 0
        failed_count = 0

        users = User.where(id: user_ids).includes(:social_user)

        users.find_each do |user|
          next unless user.social_user

          outcome = SocialUserMessages::Create.run(
            social_user: user.social_user,
            content: content,
            readed: true,
            message_type: SocialUserMessage.message_types[:bot]
          )

          if outcome.valid?
            success_count += 1
          else
            failed_count += 1
            Rails.logger.error("[BulkSend] Failed for user_id=#{user.id}: #{outcome.errors.full_messages.join(', ')}")
          end
        end

        { success: success_count, failed: failed_count }
      end
    end
  end
end
