# frozen_string_literal: true

module Notifiers
  module Users
    module LineSettings
      class LineLoginVerificationVideo < Base
        deliver_by :line

        def message
          {
            originalContentUrl: "https://toruya.com/user-bot/userbot_linelogintest.mp4",
            previewImageUrl: "https://toruya.com/user-bot/userbot_linelogintest.png"
          }.to_json
        end

        def content_type
          SocialUserMessages::Create::VIDEO_TYPE
        end

        def deliverable
          receiver.locale == "ja" || receiver.user.locale == :ja
        end
      end
    end
  end
end
