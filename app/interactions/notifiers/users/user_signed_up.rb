# frozen_string_literal: true

module Notifiers
  module Users
    class UserSignedUp < Base
      deliver_by :line

      # No default message, since all Toruya message was setup by us manually
      def message; end

      def execute
        # XXX: Send message
        super

        ::CustomMessages::Users::Next.run(
          scenario: ::CustomMessages::Users::Template::USER_SIGN_UP,
          receiver: receiver
        )
      end
    end
  end
end
