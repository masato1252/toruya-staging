# frozen_string_literal: true

module Notifiers
  module CustomerPayments
    class ChargeFailedToOwner < Base
      deliver_by :line

      object :customer_payment

      validate :receiver_should_be_user

      def message
        I18n.t("notifier.customer_payments.charge_failed_to_owner.message", user_name: receiver.name)
      end
    end
  end
end
