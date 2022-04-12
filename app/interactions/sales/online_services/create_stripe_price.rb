# frozen_string_literal: true

module Sales
  module OnlineServices
    class CreateStripePrice < ActiveInteraction::Base
      object :online_service
      string :interval
      integer :amount

      validate :validate_stripe_product_id

      def execute
        Stripe::Price.create(
          {
            unit_amount: amount,
            currency: 'jpy',
            recurring: { interval: interval },
            product: online_service.stripe_product_id,
          },
          stripe_account: online_service.user.stripe_provider.uid
        )
      rescue Stripe::StripeError => e
        Rollbar.error(e)
        errors.add(:online_service, :something_wrong)
      end

      private

      def validate_stripe_product_id
        unless online_service.stripe_product_id
          errors.add(:online_service, :invalid_product)
        end
      end
    end
  end
end
