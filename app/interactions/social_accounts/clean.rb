# frozen_string_literal: true

module SocialAccounts
  class Clean < ActiveInteraction::Base
    object :user

    def execute
      account = user.social_accounts.first
      outcome = SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: account)

      if outcome.invalid?
        Rollbar.error(outcome.errors.full_messages.join(", "), user_id: user.id)
      end

      if account
        stale_customer_ids = account.social_customers.pluck(:id)
        if stale_customer_ids.any?
          SocialMessage.where(social_customer_id: stale_customer_ids)
                       .update_all(social_customer_id: nil)
          account.social_customers.delete_all
        end

        account.update(
          channel_secret: nil,
          channel_token: nil,
          label: nil,
          login_channel_secret: nil,
          basic_id: nil,
          channel_id: nil,
          login_channel_id: nil
        )
      end

      account
    end
  end
end
