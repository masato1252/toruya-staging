# frozen_string_literal: true

module Sales
  module OnlineServices
    class Cancel < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      def execute
        if relation.pending?
          relation.canceled_payment_state!
        end

        relation
      end
    end
  end
end
