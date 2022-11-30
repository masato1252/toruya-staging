# frozen_string_literal: true

require "slack_client"

module Notifiers
  module Users
    module Notifications
      class LineSettings < Base
        deliver_by :line
        validate :receiver_should_be_user

        def message
          # TODO: Send line setting help message automatically
        end

        private

        def deliverable
          unless receiver.social_account&.line_settings_finished?
            SlackClient.send(channel: 'toruya_users_support', text: "🚑 user: #{receiver.id}, doesn't finished their line setting yet. #{url_helpers.admin_chats_url(user_id: receiver.id)}") if Rails.env.production?
          end

          false
        end
      end
    end
  end
end
