# frozen_string_literal: true

module Notifiers
  module Customers
    module CustomerPayments
      class ChargeFailedToCustomer < Base
        object :customer_payment

        validate :receiver_should_be_customer

        def message
          I18n.t(
            "notifier.customer_payments.charge_failed_to_customer.message",
            customer_name: receiver.name,
            service_title: sale_page.product_name,
            shop_name: online_service.company.company_name,
            shop_phone: online_service.company.company_phone_number,
            customer_status_online_service_url: url_helpers.customer_status_online_service_url(
              slug: online_service.slug,
              encrypted_social_service_user_id: MessageEncryptor.encrypt(customer_payment.customer&.social_customer&.social_user_id),
              encrypted_customer_id: MessageEncryptor.encrypt(customer_payment.customer_id)
            )
          )
        end

        private

        def sale_page
          customer_payment.product.sale_page
        end

        def online_service
          customer_payment.product.online_service
        end
      end
    end
  end
end
