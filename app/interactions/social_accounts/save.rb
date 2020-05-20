require "message_encryptor"

module SocialAccounts
  class Save < ActiveInteraction::Base
    object :user
    object :social_account, default: nil
    string :channel_id
    string :channel_token
    string :channel_secret
    string :label

    def execute
      begin
        SocialAccount.transaction do
          social_account ||= user.social_accounts.find_or_initialize_by(channel_id: channel_id)
          social_account.update(
            channel_token: MessageEncryptor.encrypt(channel_token),
            channel_secret: MessageEncryptor.encrypt(channel_secret),
            channel_id: channel_id,
            label: label
          )

          if social_account.invalid?
            errors.merge!(social_account.errors)
          end

          social_account
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end
end
