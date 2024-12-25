# frozen_string_literal: true

module Notifiers
  module Users
    module LineSettings
      class VerifyFailedVideo < Base
        deliver_by :line

        def message
          {
            originalContentUrl: "https://toruya.com/user-bot/userbot_messageerror.mp4",
            previewImageUrl: "https://toruya.com/user-bot/userbot_messageerror.png"
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
end
