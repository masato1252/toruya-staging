# frozen_string_literal: true

module Notifiers
  module Users
    module BusinessHealthChecks
      class NoEnoughMessage < Base
        deliver_by :line
        validate :receiver_should_be_user

        # No default message, since all Toruya message was setup by us manually
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

        self.nth_time_scenario = ::CustomMessages::Users::Template::NO_ENOUGH_MESSAGE
      end
    end
  end
end
