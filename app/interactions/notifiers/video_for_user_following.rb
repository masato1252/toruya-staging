# frozen_string_literal: true

module Notifiers
  class VideoForUserFollowing < Base
    deliver_by :line

    def message
      {
        originalContentUrl: "https://toruya.com/user-bot/userbot_addfriend.mp4",
        previewImageUrl: "https://toruya.com/user-bot/userbot_addfriend.png"
      }.to_json
    end

    def content_type
      SocialUserMessages::Create::VIDEO_TYPE
    end
  end
end
