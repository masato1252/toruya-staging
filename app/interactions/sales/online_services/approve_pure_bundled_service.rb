# frozen_string_literal: true

module Sales
  module OnlineServices
    class ApprovePureBundledService < ActiveInteraction::Base
      object :bundled_service
      object :bundler_relation, class: OnlineServiceCustomerRelation

      def execute
        relation = compose(
          ::Sales::OnlineServices::Apply,
          sale_page: sale_page,
          online_service: online_service,
          customer: customer,
          payment_type: SalePage::PAYMENTS[:bundler]
        )

        relation.permission_state = :active
        new_expire_at = bundled_service.current_expire_time
        relation.expire_at = new_expire_at
        relation.bundled_service_id = bundled_service.id
        relation.save
      end

      private

      def online_service
        @online_service ||= bundled_service.online_service
      end

      def customer
        @customer ||= bundler_relation.customer
      end

      def sale_page
        @sale_page ||= bundler_relation.sale_page
      end

      def user
        @user ||= customer.user
      end
    end
  end
end
