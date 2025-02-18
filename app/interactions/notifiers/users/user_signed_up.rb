# frozen_string_literal: true

module Notifiers
  module Users
    class UserSignedUp < Base
      deliver_by_priority [:line, :sms, :email]
      validate :receiver_should_be_user

      def message
        I18n.t("notifier.user_sign_up.message", trial_end_date: receiver.subscription.trial_expired_date.to_s)
      end

      def execute
        I18n.with_locale(receiver.locale) do
          # XXX: Send message
          super

          ::CustomMessages::Users::Next.run(
            scenario: nth_time_scenario,
            receiver: receiver,
            nth_time: nth_time
          )
        end
      end

      self.nth_time_scenario = ::CustomMessages::Users::Template::USER_SIGN_UP
    end
  end
end
