# frozen_string_literal: true

module Sales
  module OnlineServices
    class ApproveBundledService < ActiveInteraction::Base
      object :bundled_service
      object :bundler_relation, class: OnlineServiceCustomerRelation

      def execute
        existing_relation = online_service.online_service_customer_relations.find_by(online_service: online_service, customer: customer)

        if existing_relation
          if bundled_service.end_on_months && existing_relation.stripe_subscription_id && existing_relation.active?
            # existing_relation was end by subscription(Customer purchased this directly)
            compose(Sales::OnlineServices::ApproveBundledEndTimeWithExistingSubscriptionService, bundled_service: bundled_service, bundler_relation: bundler_relation, existing_relation: existing_relation)
            # if existing_relation.stripe_subscription_id
            # elsif existing_relation.bundled_service.subscription
              # existing_relation was end by subscription(Customer purchased bundler service contains this, and it was end by subscription)
              # should not give free bonus for this one, because subscription is on bundler not each sub-service
            # end
          else
            compose(Sales::OnlineServices::ApproveBundledWithExistingService, bundled_service: bundled_service, bundler_relation: bundler_relation, existing_relation: existing_relation)
          end
        else
          compose(Sales::OnlineServices::ApprovePureBundledService, inputs)
        end
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
