# frozen_string_literal: true

require "slack_client"

# https://stripe.com/docs/refunds#tracing-refunds
# https://developer.squareup.com/explorer/square/refunds-api/refund-payment
# https://developer.squareup.com/reference/square/refunds-api/refund-payment
class CustomerPayments::SquareRefund < ActiveInteraction::Base
  include RefundMethods
  object :customer_payment
  object :amount, class: Money

  def execute
    customer_payment.transaction do
      square_payment_response = owner.square_client.refunds.refund_payment(
        body: {
          idempotency_key: SecureRandom.uuid,
          payment_id: customer_payment.charge_details.dig("payment", "id"),
          amount_money: {
            amount: amount.fractional,
            currency: amount.currency.to_s
          },
          :autocomplete => true,
          :reference_id => "customer_payment-#{customer_payment.id}"
        }
      )

      if square_payment_response.success?
        refund_payment(square_payment_response.data.as_json)
      elsif square_payment_response.errors.first[:category] == "REFUND_ERROR"
        Rollbar.error("Square refund failed", toruya_service_charge: customer_payment.id, square_charge: square_payment_response.errors, rails_env: Rails.configuration.x.env)

        errors.add(:customer_payment, :refund_disputed_payment)
      else
        Rollbar.error("Square refund failed", toruya_service_charge: customer_payment.id, square_charge: square_payment_response.errors, rails_env: Rails.configuration.x.env)

        errors.add(:customer_payment, :else)
      end
    end
  end
end
