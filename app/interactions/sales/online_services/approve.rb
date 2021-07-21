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

          customer.write_attribute(:online_service_ids, (customer.read_attribute(:online_service_ids).concat([online_service.id.to_s])).uniq)
          customer.touch

          Notifiers::OnlineServices::Purchased.perform_later(receiver: customer.social_customer, customer: customer, sale_page: relation.sale_page)
        end

        relation
      end
    end
  end
end
