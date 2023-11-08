# frozen_string_literal: true

module SocialAccounts
  class Clean < ActiveInteraction::Base
    object :user

    def execute
      account = user.social_accounts.first
      outcome = SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: account)

      if outcome.valid?
        user.social_customers.where(is_owner: true).update_all(is_owner: false, customer_id: nil)
        account&.update(
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
