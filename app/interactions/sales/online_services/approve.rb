# frozen_string_literal: true

module Sales
  module OnlineServices
    class Approve < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation
      object :customer
      object :online_service
      boolean :notify, default: true

      def execute
        if relation.pending?
          relation.permission_state = :active
          relation.paid_at = Time.current
          relation.expire_at = online_service.current_expire_time
          relation.paid_payment_state!

          customer.update(online_service_ids: customer.online_service_ids.concat([relation.sale_page.product.id]).uniq)

          if notify
            Notifiers::OnlineServices::Purchased.perform_later(receiver: customer.social_customer, customer: customer, sale_page: relation.sale_page)
          end
        end

        relation
      end
    end
  end
end
