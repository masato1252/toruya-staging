# frozen_string_literal: true

module Sales
  module OnlineServices
    class Cancel < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_relation_current

      def execute
        relation.update(payment_state: :canceled, permission_state: :pending)
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
