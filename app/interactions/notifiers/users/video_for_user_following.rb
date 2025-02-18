# frozen_string_literal: true

module Notifiers
  module Users
    class VideoForUserFollowing < Base
      deliver_by_priority [:line, :sms, :email]

      def message
        {
          originalContentUrl: "https://toruya.com/user-bot/userbot_addfriend.mp4",
          previewImageUrl: "https://toruya.com/user-bot/userbot_addfriend.png"
        }.to_json
      end

      def content_type
        SocialUserMessages::Create::VIDEO_TYPE
      end

      def deliverable
        receiver.japanese?
      end
    end
  end
end
