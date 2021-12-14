# frozen_string_literal: true

module Notifiers
  module CustomerPayments
    class NotFirstTimeChargeSuccessfully < Base
      deliver_by :line

      object :customer_payment

      validate :receiver_should_be_customer

      def message
        I18n.t(
          "notifier.customer_payments.not_first_time_charge_successfully.message",
          customer_name: receiver.display_last_name,
          service_title: customer_payment.product.product_name,
          shop_name: sale_page.product.company.company_name,
          online_service_customer_status_url: "https://url.com",
        )
      end

      private

      def sale_page
        customer_payment.product
      end
    end
  end
end
