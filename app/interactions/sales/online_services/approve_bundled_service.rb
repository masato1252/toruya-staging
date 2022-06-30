# frozen_string_literal: true

module Sales
  module OnlineServices
    class ApproveBundledService < ActiveInteraction::Base
      object :bundled_service
      object :bundler_relation, class: OnlineServiceCustomerRelation

      def execute
        existing_relation = online_service.online_service_customer_relations.find_by(online_service: online_service, customer: customer)

        relation = compose(
          ::Sales::OnlineServices::Apply,
          sale_page: sale_page,
          online_service: online_service,
          customer: customer,
          payment_type: SalePage::PAYMENTS[:bundler]
        )

        if relation.inactive?
          relation = compose(
            ::Sales::OnlineServices::Reapply,
            online_service_customer_relation: relation,
            payment_type: SalePage::PAYMENTS[:bundler]
          )
        end

        relation.permission_state = :active
        new_expire_at = bundled_service.current_expire_time
        # Overwrite original plan?
        relation.sale_page = sale_page
        relation.product_details = OnlineServiceCustomerProductDetails.build(sale_page: sale_page, payment_type: SalePage::PAYMENTS[:bundler])
        relation.bundled_service_id = bundled_service.id

        unless existing_relation
          relation.expire_at = new_expire_at
        end

        if existing_relation && existing_relation.expire_at
          if new_expire_at && new_expire_at > existing_relation.expire_at
            relation.expire_at = new_expire_at
          end

          if new_expire_at.nil?
            relation.expire_at = nil
          end
        end

        # existing_relation forever/subscription
        if existing_relation && existing_relation.expire_at.nil?
          # subscription/membership existing relation
          if bundled_service.end_on_months && online_service.recurring_charge_required? && existing_relation.stripe_subscription_id
            # Give bonus when existing_relation is recurring
            coupon_id = "free-period-service-#{online_service.id}-customer-#{customer.id}-sale_page-#{sale_page.id}"
            Stripe::Coupon.create(
              { id: coupon_id, percent_off: 100, duration: 'repeating', duration_in_months: bundled_service.end_on_months },
              { stripe_account: user.stripe_provider.uid }
            )
            compose(
              StripeSubscriptions::ApplySubscriptionCoupon,
              stripe_subscription_id: existing_relation.stripe_subscription_id,
              coupon_id: coupon_id,
              stripe_account: user.stripe_provider.uid
            )
          end

          # existing_relation is subscription contract
          if new_expire_at.nil? && existing_relation.stripe_subscription_id # only existing relation got stripe_subscription_id
            compose(
              StripeSubscriptions::Delete,
              stripe_subscription_id: existing_relation.stripe_subscription_id,
              stripe_account: user.stripe_provider.uid
            )
            existing_relation.update(stripe_subscription_id: nil)
          end

          # If existing_relation use real forever contract, don't use new bundled contract
          is_existing_relation_forever = existing_relation.bundled_service_id.nil? || !existing_relation.bundled_service.subscription
          if bundled_service.subscription && is_existing_relation_forever
            relation.bundled_service_id = existing_relation.bundled_service_id
            # TODO: new or old contract?
            # relation.sale_page = existing_relation.sale_page
            # relation.product_details = existing_relation.product_details
          end
        end

        relation.save

        ::OnlineServices::Attend.run(customer: customer, online_service: online_service)
        ::Sales::OnlineServices::SendLineCard.run(relation: relation)

        relation
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
