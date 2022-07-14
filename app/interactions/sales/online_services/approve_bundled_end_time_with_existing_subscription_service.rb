# frozen_string_literal: true

module Sales
  module OnlineServices
    class ApproveBundledEndTimeWithExistingSubscriptionService < ActiveInteraction::Base
      object :bundled_service
      object :bundler_relation, class: OnlineServiceCustomerRelation
      object :existing_relation, class: OnlineServiceCustomerRelation

      validate :validate_existing_relation_with_bundled_service

      def execute
        existing_relation.with_lock do
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
          # existing_relation subscription and bundled service got end time case,
          # using original relation just giving free bonus
          # but create a payments to represent it
          payment = customer.customer_payments.new(
            product: existing_relation,
            amount_cents: 0,
            amount_currency: Money.default_currency.iso_code,
            charge_at: Time.current,
            expired_at: Time.current.advance(months: 3),
            manual: false,
            order_id: CustomerPaymentBonus.new(sale_page_id: SalePage.last.id, bonus_month: 3).to_json,
            stripe_charge_details: {}
          )
          payment.completed!

          ::OnlineServices::Attend.run(customer: customer, online_service: online_service)
          ::Sales::OnlineServices::SendLineCard.run(relation: existing_relation)

          existing_relation
        end
      end

      private

      def validate_existing_relation_with_bundled_service
        if bundled_service.end_on_months.nil? || existing_relation.stripe_subscription_id.nil? || existing_relation.pending?
          # should go ApproveBundledWithExistingService
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
