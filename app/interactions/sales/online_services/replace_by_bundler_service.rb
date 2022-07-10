# frozen_string_literal: true

module Sales
  module OnlineServices
    class ReplaceByBundlerService < ActiveInteraction::Base
      object :existing_online_service_customer_relation, class: OnlineServiceCustomerRelation
      object :bundler_relation, class: OnlineServiceCustomerRelation
      string :payment_type

      def execute
        OnlineServiceCustomerRelation.transaction do
          existing_online_service_customer_relation.current = nil
          existing_online_service_customer_relation.pending!

          online_service.online_service_customer_relations.create!(
            sale_page: sale_page,
            customer: customer,
            product_details: OnlineServiceCustomerProductDetails.build(sale_page: sale_page, payment_type: payment_type)
          )
        end
      end

      private

      def sale_page
        @sale_page ||= bundler_relation.sale_page
      end

      def online_service
        @online_service ||= existing_online_service_customer_relation.online_service
      end

      def customer
        @customer ||= bundler_relation.customer
      end
    end
  end
end
