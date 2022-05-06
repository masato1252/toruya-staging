# frozen_string_literal: true

module Notifiers
  module Users
    class VideoForUserCreatedShop < Base
      deliver_by :line

      def message
        {
          originalContentUrl: "https://toruya.com/user-bot/userbot_signedup202202.mp4",
          previewImageUrl: "https://toruya.com/user-bot/userbot_signedup202202.png"
        }.to_json
      end

      def content_type
        SocialUserMessages::Create::VIDEO_TYPE
      end
    end
  end
end
