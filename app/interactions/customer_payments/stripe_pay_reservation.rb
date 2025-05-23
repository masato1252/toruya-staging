# frozen_string_literal: true

require "slack_client"

class CustomerPayments::StripePayReservation < ActiveInteraction::Base
  object :reservation_customer
  object :payment, class: CustomerPayment
  string :payment_intent_id, default: nil

  def execute
    customer.reload

    begin
      if payment_intent_id
        payment_intent = Stripe::PaymentIntent.retrieve(
          payment_intent_id,
          stripe_account: customer.user.stripe_provider.uid
        )
      else
        payment_intent = Stripe::PaymentIntent.create(
          {
            amount: reservation_customer.booking_amount.fractional * reservation_customer.booking_amount.currency.default_subunit_to_unit,
            currency: reservation_customer.booking_amount.currency.iso_code,
            customer: customer.stripe_customer_id,
            description: "#{reservation_customer.booking_options.map(&:name).join(", ")}".first(STRIPE_DESCRIPTION_LIMIT),
            metadata: {
              reservation_customer_id: reservation_customer.id,
              customer_id: customer.id,
              customer_name: customer.name,
              reservation_id: reservation.id
            },
            setup_future_usage: 'off_session',
            confirmation_method: 'automatic',
            capture_method: 'automatic',
            payment_method_types: ['card'],
          },
          stripe_account: customer.user.stripe_provider.uid
        )
      end

      payment.stripe_charge_details = payment_intent.as_json

      case payment_intent.status
      when 'succeeded'
        payment.completed!
        if Rails.configuration.x.env.production?
          SlackClient.send(channel: 'sayhi', text: "[OK] 🎉Booking Page #{Rails.application.routes.url_helpers.booking_page_url(reservation_customer.booking_page_id)} Stripe charge💰")
        end
      when 'requires_action', 'requires_payment_method', 'requires_confirmation', "requires_source", "processing"
        payment.stripe_charge_details = payment_intent.as_json
        payment.save!
        errors.add(:payment, :requires_action, client_secret: payment_intent.client_secret)
      when 'canceled'
        payment.auth_failed!
        errors.add(:payment, :canceled)
      else
        payment.auth_failed!
        errors.add(:payment, :failed)
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
