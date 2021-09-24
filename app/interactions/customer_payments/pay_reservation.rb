# frozen_string_literal: true

require "slack_client"

class CustomerPayments::PayReservation < ActiveInteraction::Base
  object :reservation_customer

  def execute
    order_id = SecureRandom.hex(8).upcase

    payment = customer.customer_payments.create!(
      product: reservation_customer,
      amount: reservation_customer.booking_amount,
      charge_at: Time.current,
      manual: true,
      order_id: order_id
    )

    begin
      stripe_charge = Stripe::Charge.create(
        {
          amount: reservation_customer.booking_amount.fractional,
          currency: Money.default_currency.iso_code,
          customer: customer.stripe_customer_id,
          description: "#{reservation_customer.booking_page.name} - #{reservation_customer.booking_option.name}".first(STRIPE_DESCRIPTION_LIMIT),
          statement_descriptor: "#{reservation_customer.booking_page.name} - #{reservation_customer.booking_option.name}".first(STRIPE_DESCRIPTION_LIMIT),
          metadata: {
            reservation_customer_id: reservation_customer.id
          }
        },
        stripe_account: customer.user.stripe_provider.uid
      )

      payment.stripe_charge_details = stripe_charge.as_json
      payment.completed!

      if Rails.configuration.x.env.production?
        SlackClient.send(channel: 'sayhi', text: "[OK] 🎉Booking Page #{reservation_customer.booking_page_id} Stripe charge💰")
      end
    rescue Stripe::CardError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.auth_failed!
      errors.add(:customer, :auth_failed)

      Rollbar.error(error, toruya_service_charge: payment.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue Stripe::StripeError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.processor_failed!
      errors.add(:customer, :processor_failed)

      Rollbar.error(error, toruya_service_charge: payment.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue => e
      Rollbar.error(e)
      errors.add(:customer, :something_wrong)
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
