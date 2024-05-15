# frozen_string_literal: true

require "slack_client"

# https://stripe.com/docs/refunds#tracing-refunds
class CustomerPayments::Refund < ActiveInteraction::Base
  include RefundMethods

  object :customer_payment
  object :amount, class: Money

  validate :validate_refundable
  validate :validate_amount

  def execute
    case customer_payment.provider
    when CustomerPayment.providers[:stripe_connect]
      compose(CustomerPayments::StripeRefund, customer_payment: customer_payment, amount: amount)
    when CustomerPayment.providers[:square]
      compose(CustomerPayments::SquareRefund, customer_payment: customer_payment, amount: amount)
    end
  end
end
