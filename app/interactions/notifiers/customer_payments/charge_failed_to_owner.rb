# frozen_string_literal: true

module Notifiers
  module CustomerPayments
    class ChargeFailedToOwner < Base
      deliver_by :line

      object :customer_payment

      validate :receiver_should_be_user

      def message
        I18n.t(
          "notifier.customer_payments.charge_failed_to_owner.message",
          user_name: receiver.name,
          customer_status_online_service_url: url_helpers.customer_status_online_service_url(
            slug: customer_payment.product.slug,
            encrypted_social_service_user_id: MessageEncryptor.encrypt(customer_payment.customer.social_customer.social_user_id)
          )
        )
      end
    end
  end
end
