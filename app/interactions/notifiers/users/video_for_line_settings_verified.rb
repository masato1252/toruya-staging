# frozen_string_literal: true

module Notifiers
  module Users
    class VideoForLineSettingsVerified < Base
      deliver_by :line

      def message
        {
          originalContentUrl: "https://toruya.com/user-bot/userbot_linesettingdone202202.mp4",
          previewImageUrl: "https://toruya.com/user-bot/userbot_linesettingdone202202.png"
        }.to_json
      end

      def content_type
        SocialUserMessages::Create::VIDEO_TYPE
      end
    end
  end
end
