# frozen_string_literal: true

module Notifiers
  module Users
    module BookingPages
      class SecondCreation < Base
        deliver_by :line

        # No default message, since all Toruya message was setup by us manually
        def message; end

        def execute
          # XXX: Send message
          super

          ::CustomMessages::Users::Next.run(
            scenario: ::CustomMessages::Users::Template::SECOND_BOOKING_PAGE_CREATED,
            receiver: receiver
          )
        end
      end
    end
  end
end
