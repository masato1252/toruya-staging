require "message_encryptor"

module SocialAccounts
  class Save < ActiveInteraction::Base
    object :user
    object :social_account, default: nil
    string :channel_id
    string :channel_token
    string :channel_secret
    string :label
    string :basic_id

    def execute
      begin
        SocialAccount.transaction do
          account = social_account || user.social_accounts.new

          account.update(
            channel_token: MessageEncryptor.encrypt(channel_token),
            channel_secret: MessageEncryptor.encrypt(channel_secret),
            channel_id: channel_id,
            label: label,
            basic_id: basic_id
          )

          if account.invalid?
            errors.merge!(account.errors)
          else
            compose(SocialAccounts::RichMenus::CustomerGuest, social_account: account)
            compose(SocialAccounts::RichMenus::CustomerReservations, social_account: account)
          end

          account
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end
end
