# frozen_string_literal: true

class TwUserBotSocialAccount
  class << self
    def client(locale = 'ja')
      @@tw_client ||= Line::Bot::Client.new { |config|
        config.channel_token = Rails.application.secrets[:tw][:toruya_user_bot_token]
        config.channel_secret = Rails.application.secrets[:tw][:toruya_user_bot_secret]
      }
    end
  end
end