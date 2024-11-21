# frozen_string_literal: true

class UserBotSocialAccount
  class << self
    def client
      @@client ||= Line::Bot::Client.new { |config|
        config.channel_token = Rails.application.secrets[:ja][:toruya_user_bot_token]
        config.channel_secret = Rails.application.secrets[:ja][:toruya_user_bot_secret]
      }
    end
  end
end