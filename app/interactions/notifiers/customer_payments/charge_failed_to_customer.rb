# frozen_string_literal: true

module Notifiers
  module CustomerPayments
    class ChargeFailedToCustomer < Base
      deliver_by :line

      object :customer_payment

      validate :receiver_should_be_customer

      def message
        I18n.t(
          "notifier.customer_payments.charge_failed_to_customer.message",
          customer_name: receiver.display_last_name,
          service_title: customer_payment.product.product_name,
          shop_name: sale_page.product.company.company_name,
          shop_phone: sale_page.product.company.company_phone_number,
          customer_status_online_service_url: url_helpers.customer_status_online_service_url(
            slug: customer_payment.product.slug,
            encrypted_social_service_user_id: MessageEncryptor.encrypt(customer_payment.customer.social_customer.social_user_id)
          )
        )
      end

      private

      def sale_page
        customer_payment.product
      end
    end
  end
end
