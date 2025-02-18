# frozen_string_literal: true

module Notifiers
  module Customers
    module CustomerPayments
      class NotFirstTimeChargeSuccessfully < Base
        object :customer_payment

        validate :receiver_should_be_customer

        def message
          I18n.t(
            "notifier.customer_payments.not_first_time_charge_successfully.message",
            customer_name: receiver.name,
            service_title: sale_page.product_name,
            shop_name: online_service.company.company_name,
            customer_status_online_service_url: url_helpers.customer_status_online_service_url(
              slug: online_service.slug,
              encrypted_social_service_user_id: MessageEncryptor.encrypt(customer_payment.customer.social_customer.social_user_id)
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
