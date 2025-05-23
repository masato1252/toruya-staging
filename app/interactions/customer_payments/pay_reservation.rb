# frozen_string_literal: true

require "slack_client"
require "order_id"

class CustomerPayments::PayReservation < ActiveInteraction::Base
  object :reservation_customer
  object :payment_provider, class: AccessProvider
  string :source_id, default: nil
  string :location_id, default: nil
  string :payment_intent_id, default: nil

  def execute
    order_id = OrderId.generate

    payment = customer.customer_payments.create!(
      product: reservation_customer,
      amount: reservation_customer.booking_amount,
      charge_at: Time.current,
      manual: true,
      order_id: order_id,
      provider: payment_provider.provider
    )

    case payment_provider.provider
    when AccessProvider.providers[:stripe_connect]
      compose(CustomerPayments::StripePayReservation, reservation_customer: reservation_customer, payment: payment, payment_intent_id: payment_intent_id)
    when AccessProvider.providers[:square]
      compose(CustomerPayments::SquarePayReservation, reservation_customer: reservation_customer, payment: payment, source_id: source_id, location_id: location_id)
    end

    payment
  end

  private

  def customer
    @customer ||= reservation_customer.customer
  end

  def reservation
    @reservation ||= reservation_customer.reservation
  end
end
