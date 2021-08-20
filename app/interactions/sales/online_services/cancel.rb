# frozen_string_literal: true

module Sales
  module OnlineServices
    class Cancel < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      def execute
        relation.update(payment_state: :canceled, permission_state: :pending)
        relation
      end
    end
  end
end
