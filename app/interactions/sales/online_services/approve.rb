# frozen_string_literal: true

module Sales
  module OnlineServices
    class Approve < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_relation_current

      def execute
        if relation.pending?
          relation.permission_state = :active
          relation.expire_at = relation.online_service.current_expire_time

          if relation.sale_page.free?
            relation.free_payment_state!
          else
            # paid_at => bought at, when customer bought this product, it should equals first time pay.
            relation.paid_at = Time.current
            relation.save
          end

          ::OnlineServices::Attend.run(customer: relation.customer, online_service: relation.online_service, sale_page: relation.sale_page)
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
