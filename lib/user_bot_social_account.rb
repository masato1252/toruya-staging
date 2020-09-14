class UserBotSocialAccount
  class << self
    def client
      @@client ||= Line::Bot::Client.new { |config|
        config.channel_token = Rails.application.secrets.toruya_user_bot_token
        config.channel_secret = Rails.application.secrets.toruya_user_bot_secret
      }
    end
  end
end
