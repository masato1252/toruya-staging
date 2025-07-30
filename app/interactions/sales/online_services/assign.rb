# frozen_string_literal: true

require "message_encryptor"
require "translator"

module Sales
  module OnlineServices
    class Assign < ActiveInteraction::Base
      object :online_service
      object :customer

      def execute
        relation =
          if online_service.bundler?
            compose(
              Sales::OnlineServices::PurchaseBundlerService,
              online_service: online_service,
              customer: customer,
              payment_type: SalePage::PAYMENTS[:assignment]
            )
          else
            compose(
              Sales::OnlineServices::PurchaseNormalService,
              online_service: online_service,
              customer: customer,
              payment_type: SalePage::PAYMENTS[:assignment]
            )
          end

        CustomerPayments::ApproveManually.run(online_service_customer_relation: relation)
        relation
      end
    end
  end
end
