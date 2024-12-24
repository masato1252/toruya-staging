# frozen_string_literal: true

module Sales
  module OnlineServices
    class Apply < ActiveInteraction::Base
      object :online_service
      object :sale_page, default: nil
      object :customer
      string :payment_type

      def execute
        begin
          OnlineServiceCustomerRelation.transaction do
            online_service.online_service_customer_relations
              .create_with(
                sale_page: sale_page,
                product_details: OnlineServiceCustomerProductDetails.build(sale_page: sale_page, payment_type: payment_type))
              .find_or_create_by(online_service: online_service, customer: customer)
          end
        rescue ActiveRecord::RecordNotUnique
          retry
        end
      end
    end
  end
end
