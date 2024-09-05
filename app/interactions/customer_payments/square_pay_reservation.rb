# frozen_string_literal: true

require "slack_client"

class CustomerPayments::SquarePayReservation < ActiveInteraction::Base
  object :reservation_customer
  object :payment, class: CustomerPayment
  string :source_id
  string :location_id

  def execute
    customer.reload

    begin
      square_payment_response = owner.square_client.payments.create_payment(
        body: {
          :source_id => source_id,
          :idempotency_key => payment.order_id,
          :amount_money => {
            :amount => reservation_customer.booking_amount.fractional,
            :currency => Money.default_currency.iso_code
          },
          :autocomplete => true,
          :customer_id => customer.square_customer_id,
          :location_id => location_id,
          :reference_id => "customer_payment-#{payment.id}",
          :note => "#{reservation_customer.booking_option.name}".first(STRIPE_DESCRIPTION_LIMIT)
        }
      )

      payment.charge_details = square_payment_response.data.as_json

      if square_payment_response.success?
        payment.completed!
      elsif square_payment_response.errors.first[:category] == "PAYMENT_METHOD_ERROR"
        Rollbar.error("Square charge failed", toruya_service_charge: payment.id, square_charge: square_payment_response.errors, rails_env: Rails.configuration.x.env)

        payment.auth_failed!
        errors.add(:customer, :auth_failed)
      else
        Rollbar.error("Square charge failed", toruya_service_charge: payment.id, square_charge: square_payment_response.errors, rails_env: Rails.configuration.x.env)

        payment.processor_failed!
        errors.add(:customer, :processor_failed)
      end

      if Rails.configuration.x.env.production?
        SlackClient.send(channel: 'sayhi', text: "[OK] 🎉Booking Page #{Rails.application.routes.url_helpers.booking_page_url(reservation_customer.booking_page_id)} Square charge💰")
      end
    rescue => e
      Rollbar.error(e)
      errors.add(:customer, :something_wrong)
    end

    payment
  end

  private

  def owner
    @owner ||= customer.user
  end

  def customer
    @customer ||= reservation_customer.customer
  end

  def reservation
    @reservation ||= reservation_customer.reservation
  end
end
