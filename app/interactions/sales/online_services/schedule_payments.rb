# frozen_string_literal: true

module Sales
  module OnlineServices
    class SchedulePayments < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_relation_current

      def execute
        relation.price_details.each do |price_details|
          unless relation.customer_payments.where(order_id: price_details.order_id).completed.exists?
            # TODO: need failed notification
            CustomerPayments::PurchaseOnlineService.perform_at(
              schedule_at: Time.zone.parse(price_details.charge_at),
              online_service_customer_relation: relation
            )
          end
        end
        relation
      end

      private

      def validate_relation_current
        unless relation.current
          errors.add(:relation, :current_true_is_required)
        end
      end
    end
  end
end
