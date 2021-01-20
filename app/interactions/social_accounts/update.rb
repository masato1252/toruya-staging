require "message_encryptor"

module SocialAccounts
  class Update < ActiveInteraction::Base
    object :user
    string :update_attribute

    hash :attrs, default: nil, strip: false do
      string :channel_id, default: nil
      string :channel_token, default: nil
      string :channel_secret, default: nil
      string :label, default: nil
      string :basic_id, default: nil
      string :login_channel_id, default: nil
      string :login_channel_secret, default: nil
    end

    def execute
      begin
        SocialAccount.transaction do
          account = user.social_accounts.first || user.social_accounts.new

          case update_attribute
          when "channel_id", "label", "basic_id", "login_channel_id"
            account.update(attrs.slice(update_attribute))
          when "channel_token"
            account.update(channel_token: MessageEncryptor.encrypt(attrs[:channel_token]))
          when "channel_secret"
            account.update(channel_secret: MessageEncryptor.encrypt(attrs[:channel_secret]))
          when "login_channel_secret"
            account.update(login_channel_secret: MessageEncryptor.encrypt(attrs[:login_channel_secret]))
          end

          if account.bot_data_finished?
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
