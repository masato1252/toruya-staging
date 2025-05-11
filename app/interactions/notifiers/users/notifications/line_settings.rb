# frozen_string_literal: true

require "slack_client"

module Notifiers
  module Users
    module Notifications
      class LineSettings < Base
        deliver_by_priority [:line, :sms, :email]
        validate :receiver_should_be_user

        def message; end

        def execute
          # XXX: Send message
          super

          ::CustomMessages::Users::Next.run(
            scenario: nth_time_scenario,
            receiver: receiver,
            nth_time: nth_time
          )
        end

        private

        def deliverable
          !receiver.social_account&.line_settings_finished?
        end

        self.nth_time_scenario = ::CustomMessages::Users::Template::NO_LINE_SETTINGS
      end
    end
  end
end
