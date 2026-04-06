# frozen_string_literal: true

module SocialAccounts
  class Clean < ActiveInteraction::Base
    object :user

    def execute
      account = user.social_accounts.first

      Rails.logger.info("[SocialAccounts::Clean] Starting: user_id=#{user.id}, account_id=#{account&.id}")

      outcome = SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: account)

      if outcome.invalid?
        Rails.logger.warn("[SocialAccounts::Clean] SwitchToOfficial failed: #{outcome.errors.full_messages.join(', ')}")
        Rollbar.error(outcome.errors.full_messages.join(", "), user_id: user.id)
      end

      if account
        stale_customer_ids = account.social_customers.pluck(:id)
        Rails.logger.info("[SocialAccounts::Clean] Cleaning #{stale_customer_ids.size} social_customers")

        if stale_customer_ids.any?
          nullified = SocialMessage.where(social_customer_id: stale_customer_ids)
                                   .update_all(social_customer_id: nil)
          Rails.logger.info("[SocialAccounts::Clean] Nullified social_customer_id on #{nullified} social_messages")
          account.social_customers.delete_all
        end

        uid_messages_deleted = account.social_messages
                                      .where(message_type: SocialMessage.message_types[:customer])
                                      .where("raw_content ~ '^U[0-9a-f]{32}$'")
                                      .delete_all
        Rails.logger.info("[SocialAccounts::Clean] Deleted #{uid_messages_deleted} verification UID messages")

        account.update(
          channel_secret: nil,
          channel_token: nil,
          label: nil,
          login_channel_secret: nil,
          basic_id: nil,
          channel_id: nil,
          login_channel_id: nil
        )

        Rails.logger.info("[SocialAccounts::Clean] Credentials cleared. Remaining social_customers=#{account.social_customers.count}, owner_sc=#{user.reload.owner_social_customer&.id}")
      else
        Rails.logger.warn("[SocialAccounts::Clean] No social_account found for user_id=#{user.id}")
      end

      account
    end
  end
end
