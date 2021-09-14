# frozen_string_literal: true

require "slack_client"

class CustomerPayments::RefundReservation < ActiveInteraction::Base
  object :reservation_customer
  object :amount, class: Money

  validate :validate_refundable

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

        if stripe_refund.status == "succeeded"
          payment = customer.customer_payments.create!(
            product: reservation_customer,
            amount: amount,
            manual: true
          )

          payment.stripe_charge_details = stripe_refund.as_json
          payment.refunded!
          reservation_customer.refunded!
        else
          errors.add(:reservation_customer, :refund_failed)
        end
      rescue Stripe::CardError, Stripe::StripeError => error
        errors.add(:reservation_customer, :refund_failed)
      end
    end
  end

  private

  def paid_payment
    @paid_payment ||= customer.customer_payments.completed.where(product: reservation_customer).first
  end

  def validate_refundable
    errors.add(:reservation_customer, :reservation_was_refunded) if reservation_customer.refunded?
  end

  def customer
    @customer ||= reservation_customer.customer
  end
end
