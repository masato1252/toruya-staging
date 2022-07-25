# frozen_string_literal: true

module Sales
  module OnlineServices
    class ApproveBundledWithExistingService < ActiveInteraction::Base
      object :bundled_service
      object :bundler_relation, class: OnlineServiceCustomerRelation
      object :existing_relation, class: OnlineServiceCustomerRelation

      validate :validate_existing_relation_with_bundled_service

      def execute
        # Cancel(pending) the original relation then create a new one
        relation = compose(
          ::Sales::OnlineServices::ReplaceByBundlerService,
          existing_online_service_customer_relation: existing_relation,
          bundler_relation: bundler_relation,
          payment_type: SalePage::PAYMENTS[:bundler]
        )

        relation.permission_state = :active
        new_expire_at = bundled_service.current_expire_time
        relation.bundled_service_id = bundled_service.id

        if existing_relation.expire_at
          if new_expire_at && new_expire_at > existing_relation.expire_at
            relation.expire_at = new_expire_at
          else
            relation.expire_at = existing_relation.expire_at
          end

          if new_expire_at.nil?
            relation.expire_at = nil
          end
        end

        # existing relation is forever/membership subscription
        if existing_relation.expire_at.nil?
          # forever/new subscription would cancel original subscription
          if new_expire_at.nil? && existing_relation.stripe_subscription_id # only existing relation got stripe_subscription_id
            compose(
              StripeSubscriptions::Delete,
              stripe_subscription_id: existing_relation.stripe_subscription_id,
              stripe_account: user.stripe_provider.uid
            )
            existing_relation.update(stripe_subscription_id: nil)
          end

          # If existing_relation use real forever contract, don't use new bundled contract
          if bundled_service.subscription && existing_relation.forever?
            relation.bundled_service_id = existing_relation.bundled_service_id
          end
        end

        relation.save

        ::OnlineServices::Attend.run(customer: customer, online_service: online_service)

        relation
      end

      private

      def validate_existing_relation_with_bundled_service
        if bundled_service.end_on_months && existing_relation.stripe_subscription_id && existing_relation.active?
          # should go ApproveBundledEndTimeWithExistingSubscriptionService
          errors.add(:bundler_service, :invalid_flow)
        end
      end

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
