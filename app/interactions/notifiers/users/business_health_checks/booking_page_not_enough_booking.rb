# frozen_string_literal: true

module Notifiers
  module Users
    module BusinessHealthChecks
      class BookingPageNotEnoughBooking < Base
        deliver_by_priority [:line, :sms, :email]

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

        self.nth_time_scenario = ::CustomMessages::Users::Template::BOOKING_PAGE_NOT_ENOUGH_BOOKING
      end
    end
  end
end
