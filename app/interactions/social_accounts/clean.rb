# frozen_string_literal: true

module SocialAccounts
  class Clean < ActiveInteraction::Base
    object :user

    def execute
      account = user.social_accounts.first
      SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: account)
      account&.update(
        channel_secret: nil,
        channel_token: nil,
        label: nil,
        login_channel_secret: nil,
        basic_id: nil,
        channel_id: nil,
        login_channel_id: nil
      )

      account
    end
  end
end
