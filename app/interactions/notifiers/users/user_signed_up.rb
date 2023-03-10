# frozen_string_literal: true

module Notifiers
  module Users
    class UserSignedUp < Base
      deliver_by :line
      validate :receiver_should_be_user

      def message
        I18n.t("notifier.user_sign_up.message", trial_end_date: receiver.subscription.trial_expired_date.to_s)
      end

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
