# frozen_string_literal: true

require "slack_client"

# https://stripe.com/docs/refunds#tracing-refunds
class CustomerPayments::RefundReservation < ActiveInteraction::Base
  object :reservation_customer
  object :amount, class: Money

  validate :validate_refundable
  validate :validate_amount

  def execute
    paid_payment.transaction do
      begin
        stripe_refund = Stripe::Refund.create(
          {
            charge: paid_payment.stripe_charge_details["id"],
            amount: amount.fractional,
            metadata: {
              reservation_customer_id: reservation_customer.id
            }
          },
          stripe_account: customer.user.stripe_provider.uid
        )

        if stripe_refund.status == STRIPE_REFUND_STATUS[:succeeded]
          refund_payment(stripe_refund)
        else
          Rollbar.warning(
            "refund_reservation_failed",
            stripe_refund: stripe_refund.as_json,
            reservation_customer: reservation_customer.id
          )

          errors.add(:reservation_customer, :refund_failed)
        end
      rescue Stripe::CardError, Stripe::StripeError => error
        if error.code == "charge_already_refunded"
          refund_payment
        else
          Rollbar.error(error)
          errors.add(:reservation_customer, :refund_failed)
        end
      end
    end
  end

  private

  def refund_payment(stripe_refund_response = nil)
    payment = customer.customer_payments.create!(
      product: reservation_customer,
      amount: amount,
      manual: true
    )

    payment.stripe_charge_details = stripe_refund_response.as_json
    payment.refunded!
    reservation_customer.payment_refunded!
  end

  def paid_payment
    @paid_payment ||= customer.customer_payments.completed.where(product: reservation_customer).first
  end

  def customer
    @customer ||= reservation_customer.customer
  end

  def validate_refundable
    errors.add(:reservation_customer, :reservation_was_refunded) if reservation_customer.payment_refunded?
  end

  def validate_amount
    if amount > reservation_customer.booking_amount
      errors.add(:amount, :over_booking_amount)
    end

    unless amount.positive?
      errors.add(:amount, :positive_required)
    end
  end
end
