# frozen_string_literal: true

require "slack_client"

# https://stripe.com/docs/refunds#tracing-refunds
class CustomerPayments::StripeRefund < ActiveInteraction::Base
  include RefundMethods
  object :customer_payment
  object :amount, class: Money

  def execute
    customer_payment.transaction do
      begin
        stripe_refund = Stripe::Refund.create(
          {
            charge: customer_payment.stripe_charge_details["id"],
            amount: amount.fractional,
            metadata: {
              product_id: customer_payment.product_id,
              product_type: customer_payment.product_type
            }
          },
          stripe_account: customer.user.stripe_provider.uid
        )

        if stripe_refund.status == STRIPE_REFUND_STATUS[:succeeded]
          refund_payment(stripe_refund.as_json)
        else
          errors.add(:customer_payment, :else)
        end
      rescue Stripe::CardError, Stripe::StripeError => error
        Rollbar.error(error)

        case error.code
        when "charge_already_refunded"
          errors.add(:customer_payment, error.code.to_sym)
          refund_payment
        when "charge_disputed", "charge_not_refundable", "refund_disputed_payment", "return_intent_already_processed"
          errors.add(:customer_payment, error.code.to_sym)
        else
          errors.add(:customer_payment, :else)
        end
      end
    end
  end
end
