# frozen_string_literal: true

require "slack_client"

class CustomerPayments::PurchaseOnlineService < ActiveInteraction::Base
  object :online_service_customer_relation
  object :online_service_customer_price, class: OnlineServiceCustomerPrice, default: nil
  boolean :first_time_charge, default: false
  boolean :manual, default: false

  def execute
    order_id = SecureRandom.hex(8).upcase
    expire_at = online_service.current_expire_time if first_time_charge
    online_service_customer_price ||= online_service_customer_relation.price_details.first
    charging_price_amount = online_service_customer_price.amount.fractional

    payment =
      online_service_customer_relation.with_lock do
        # return payment if this order was paid
        if exists_payment = online_service_customer_relation.customer_payments.where(order_id: online_service_customer_price.order_id).completed.first
          return exists_payment
        end

        customer.customer_payments.create!(
          product: sale_page,
          amount: charging_price_amount,
          charge_at: Time.current,
          expired_at: expire_at,
          manual: manual,
          order_id: online_service_customer_price.order_id
        )
      end

    begin
      stripe_charge = Stripe::Charge.create(
        {
          amount: charging_price_amount,
          currency: Money.default_currency.iso_code,
          customer: customer.stripe_customer_id,
          description: sale_page.product_name.first(STRIPE_DESCRIPTION_LIMIT),
          metadata: {
            relation: online_service_customer_relation.id,
            sale_page: sale_page.id
          }
        },
        stripe_account: customer.user.stripe_provider.uid
      )

      payment.stripe_charge_details = stripe_charge.as_json
      payment.completed!

      if Rails.configuration.x.env.production?
        SlackClient.send(channel: 'sayhi', text: "[OK] 🎉Sale Page #{sale_page.id} Stripe charge💰")
      end
    rescue Stripe::CardError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.auth_failed!
      errors.add(:customer, :auth_failed)

      Rollbar.error(error, toruya_service_charge: online_service_customer_relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue Stripe::StripeError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.processor_failed!
      errors.add(:customer, :processor_failed)

      Rollbar.error(error, toruya_service_charge: online_service_customer_relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue => e
      Rollbar.error(e)
      errors.add(:customer, :something_wrong)
    end

    if online_service_customer_relation.paid_completed?
      online_service_customer_relation.paid_payment_state!
    else
      online_service_customer_relation.partial_paid_payment_state!
    end

    payment
  end

  private

  def sale_page
    @sale_page ||= online_service_customer_relation.sale_page
  end

  def customer
    @customer ||= online_service_customer_relation.customer
  end

  def online_service
    @online_service ||= online_service_customer_relation.online_service
  end
end
