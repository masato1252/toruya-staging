# frozen_string_literal: true

require "message_encryptor"
require "translator"

module Sales
  module OnlineServices
    class PurchaseBundlerService < ActiveInteraction::Base
      object :sale_page, default: nil
      object :online_service, default: nil
      object :customer
      string :authorize_token, default: nil
      string :payment_type
      string :payment_intent_id, default: nil
      string :stripe_subscription_id, default: nil

      validate :validate_product
      validates :payment_type, inclusion: { in: SalePage::PAYMENTS.values }

      def execute
        relation = compose(
          ::Sales::OnlineServices::Apply,
          sale_page: sale_page,
          online_service: product,
          customer: customer,
          payment_type: payment_type
        )

        return if relation.legal_to_access?

        if relation.inactive?
          relation = compose(
            ::Sales::OnlineServices::Reapply,
            online_service_customer_relation: relation,
            payment_type: payment_type
          )
        end

        case payment_type
        when SalePage::PAYMENTS[:assignment]
          Sales::OnlineServices::ApproveBundlerService.run(relation: relation)
        when SalePage::PAYMENTS[:one_time], SalePage::PAYMENTS[:multiple_times]
          Customers::StoreStripeCustomer.run(customer: customer, authorize_token: authorize_token, payment_intent_id: payment_intent_id)

          # credit card charge is synchronous request, it would return final status immediately
          if compose(CustomerPayments::PurchaseOnlineService, online_service_customer_relation: relation, first_time_charge: true, manual: true, payment_intent_id: payment_intent_id, payment_method_id: authorize_token)
            Sales::OnlineServices::ApproveBundlerService.run(relation: relation)
            Sales::OnlineServices::ScheduleCharges.run(relation: relation)
          else
            relation.failed_payment_state!
          end
        when SalePage::PAYMENTS[:month], SalePage::PAYMENTS[:year]
          Customers::StoreStripeCustomer.run(customer: customer, authorize_token: authorize_token, stripe_subscription_id: stripe_subscription_id)

          # credit card charge is synchronous request, it would return final status immediately
          compose(CustomerPayments::SubscribeOnlineService, online_service_customer_relation: relation, stripe_subscription_id: stripe_subscription_id, payment_method_id: authorize_token)
        end

        compose(Users::UpdateCustomerLatestActivityAt, user: sale_page&.user || online_service.user)
      end

      private

      def product
        @product ||= sale_page&.product || online_service
      end

      def social_customer
        @social_customer ||= customer.social_customer
      end

      def validate_product
        unless product.is_a?(OnlineService)
          errors.add(:sale_page, :invalid_product)
        end

        unless product.bundler?
          errors.add(:sale_page, :invalid_bundler_product)
        end
      end
    end
  end
end
