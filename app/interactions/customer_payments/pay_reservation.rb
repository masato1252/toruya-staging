# frozen_string_literal: true

require "slack_client"

class CustomerPayments::PayReservation < ActiveInteraction::Base
  object :reservation_customer

  def execute
    customer = reservation_customer.customer
    reservation = reservation_customer.reservation

    order_id = SecureRandom.hex(8).upcase

    payment = customer.customer_payments.create!(
      product: customer_reservation,
      amount: customer_reservation.booking_amount,
      charge_at: Time.current,
      manual: true,
      order_id: order_id
    )

    begin
      stripe_charge = Stripe::Charge.create(
        {
          amount: customer_reservation.booking_amount.fractional,
          currency: Money.default_currency.iso_code,
          customer: customer.stripe_customer_id,
          description: "#{customer_reservation.booking_page.name} - #{customer_reservation.booking_option.name}",
          statement_descriptor: "#{customer_reservation.booking_page.name} - #{customer_reservation.booking_option.name}",
          metadata: {
            reservation_customer_id: customer_reservation.id
          }
        },
        stripe_account: customer.user.stripe_provider.uid
      )

      payment.stripe_charge_details = stripe_charge.as_json
      payment.completed!

      if Rails.configuration.x.env.production?
        SlackClient.send(channel: 'sayhi', text: "[OK] 🎉Booking Page #{customer_reservation.booking_page_id} Stripe charge💰")
      end
    rescue Stripe::CardError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.auth_failed!
      errors.add(:customer, :auth_failed)

      Rollbar.error(error, toruya_service_charge: relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue Stripe::StripeError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.processor_failed!
      errors.add(:customer, :processor_failed)

      Rollbar.error(error, toruya_service_charge: relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue => e
      Rollbar.error(e)
      errors.add(:customer, :something_wrong)
    end

    payment
  end
end
