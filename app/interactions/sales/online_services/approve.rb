# frozen_string_literal: true

module Sales
  module OnlineServices
    class Approve < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation
      object :customer
      object :online_service

      def execute
        if relation.pending?
          relation.permission_state = :active
          relation.paid_at = Time.current
          relation.expire_at = online_service.current_expire_time
          relation.paid_payment_state!

          ::OnlineServices::Attend.run(customer: customer, online_service: online_service, sale_page: relation.sale_page)
        end

        relation
      end
    end
  end
end
