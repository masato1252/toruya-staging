# frozen_string_literal: true

module Sales
  module OnlineServices
    class Reapply < ActiveInteraction::Base
      object :online_service_customer_relation
      string :payment_type

      validate :validate_state

      def execute
        OnlineServiceCustomerRelation.transaction do
          online_service_customer_relation.update_columns(current: nil)

          online_service.online_service_customer_relations.create!(
            sale_page: sale_page,
            customer: customer,
            product_details: OnlineServiceCustomerProductDetails.build(sale_page: sale_page, payment_type: payment_type)
          )
        end
      end

      private

      def sale_page
        @sale_page ||= online_service_customer_relation.sale_page
      end

      def online_service
        @online_service ||= online_service_customer_relation.online_service
      end

      def customer
        @customer ||= online_service_customer_relation.customer
      end

      def validate_state
        unless online_service_customer_relation.inactive?
          errors.add(:online_service_customer_relation, :invalid_state)
        end
      end
    end
  end
end
