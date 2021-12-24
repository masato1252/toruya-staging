# frozen_string_literal: true

module Sales
  module OnlineServices
    class ScheduleCharges < ActiveInteraction::Base
      REMINDER_DAYS = 7

      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_relation_current

      def execute
        relation.price_details.each do |price_details|
          unless relation.customer_payments.where(order_id: price_details.order_id).completed.exists?
            Notifiers::OnlineServices::ChargeReminder.perform_at(
              schedule_at: price_details.charge_at.advance(days: -REMINDER_DAYS),
              receiver: relation.customer,
              online_service_customer_relation: relation,
              online_service_customer_price: price_details
            )
            CustomerPayments::PurchaseOnlineService.perform_at(
              schedule_at: price_details.charge_at,
              online_service_customer_relation: relation,
              online_service_customer_price: price_details
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
