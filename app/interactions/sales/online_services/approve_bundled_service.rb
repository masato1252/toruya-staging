# frozen_string_literal: true

module Sales
  module OnlineServices
    class ApproveBundledService < ActiveInteraction::Base
      object :bundled_service
      object :bundler_relation, class: OnlineServiceCustomerRelation

      def execute
        relation = compose(
          ::Sales::OnlineServices::Apply,
          sale_page: bundler_relation.sale_page,
          online_service: bundled_service.online_service,
          customer: bundler_relation.customer,
          payment_type: SalePage::PAYMENTS[:bundler]
        )

        # TODO: need to pick a better deal for customer
        # return if relation.legal_to_access?
        #
        # if relation.inactive?
        #   relation = compose(
        #     ::Sales::OnlineServices::Reapply,
        #     online_service_customer_relation: relation,
        #     payment_type: payment_type
        #   )
        # end

        relation.permission_state = :active
        relation.expire_at = bundled_service.current_expire_time
        relation.save

        ::OnlineServices::Attend.run(customer: relation.customer, online_service: relation.online_service)
        ::Sales::OnlineServices::SendLineCard.run(relation: relation)

        relation
      end
    end
  end
end
