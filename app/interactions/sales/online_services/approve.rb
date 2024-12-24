# frozen_string_literal: true

module Sales
  module OnlineServices
    class Approve < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_relation_current

      def execute
        relation.permission_state = :active
        relation.expire_at = relation.online_service.current_expire_time

        if relation.assignment?
          relation.paid_at = Time.current
          relation.payment_state = :pending
          relation.save
        elsif relation.sale_page&.free?
          relation.free_payment_state!
        else
          # paid_at => bought at, when customer bought this product, it should equals first time pay.
          relation.paid_at = Time.current
          relation.payment_state = :paid if relation.online_service.external?
          relation.save
        end

        ::OnlineServices::Attend.run(customer: relation.customer, online_service: relation.online_service)
        ::Notifiers::Customers::OnlineServices::Purchased.run(receiver: relation.customer, online_service: relation.online_service)
        ::Sales::OnlineServices::SendLineCard.run(relation: relation)

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
