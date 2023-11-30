# frozen_string_literal: true

require "slack_client"

# https://stripe.com/docs/refunds#tracing-refunds
class CustomerPayments::Refund < ActiveInteraction::Base
  object :customer_payment
  object :amount, class: Money

  validate :validate_refundable
  validate :validate_amount

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
          refund_payment(stripe_refund)
        else
          # Rollbar.warning(
          #   "refund_payment_failed",
          #   stripe_refund: stripe_refund.as_json,
          #   product_id: customer_payment.product_id,
          #   product_type: customer_payment.product_type
          # )

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

  private

  def refund_payment(stripe_refund_response = nil)
    payment = customer.customer_payments.create!(
      product: product,
      amount: -amount,
      manual: true
    )

    payment.stripe_charge_details = stripe_refund_response.as_json
    payment.refunded!
    product_refund
  end

  def customer
    @customer ||= customer_payment.customer
  end

  def product
    customer_payment.product
  end

  def product_refund
    product.is_a?(ReservationCustomer) ? product.payment_refunded! : product.refunded_payment_state!
  end

  def payment_refunded
    product.is_a?(ReservationCustomer) ? product.payment_refunded? : product.refunded_payment_state?
  end

  def validate_refundable
    errors.add(:customer_payment, :charge_already_refunded) if payment_refunded
  end

  def validate_amount
    if amount > customer_payment.amount
      errors.add(:customer_payment, :else)
    end

    unless amount.positive?
      errors.add(:customer_payment, :else)
    end
  end
end
