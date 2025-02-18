# frozen_string_literal: true

module Notifiers
  module Users
    module CustomerPayments
      class ChargeFailedToOwner < Base
        deliver_by_priority [:line, :sms, :email]

        object :customer_payment

        validate :receiver_should_be_user

        def message
          I18n.t("notifier.customer_payments.charge_failed_to_owner.message", user_name: receiver.name, customer_name: customer_payment.customer.name)
        end
      end
    end
  end
end
