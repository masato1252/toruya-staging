# frozen_string_literal: true

require "slack_client"

class CustomerPayments::PurchaseOnlineService < ActiveInteraction::Base
  object :online_service_customer_relation
  object :online_service_customer_price, class: OnlineServiceCustomerPrice, default: nil
  boolean :first_time_charge, default: false
  boolean :manual, default: false

  validate :validate_online_service_customer_relation_state

  def execute
    expire_at = online_service.current_expire_time if first_time_charge
    price_details = online_service_customer_price || online_service_customer_relation.price_details.first
    charging_price_amount = price_details.amount_with_currency.fractional

    payment =
      online_service_customer_relation.with_lock do
        if existing_payment = online_service_customer_relation.customer_payments.where(order_id: price_details.order_id).completed.take
          return existing_payment
        end

        customer.customer_payments.create!(
          product: online_service_customer_relation,
          amount: charging_price_amount,
          charge_at: Time.current,
          expired_at: expire_at,
          manual: manual,
          order_id: price_details.order_id
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

      if online_service_customer_relation.paid_completed?
        online_service_customer_relation.paid_payment_state!
      else
        online_service_customer_relation.partial_paid_payment_state!
      end

      unless first_time_charge
        Notifiers::CustomerPayments::NotFirstTimeChargeSuccessfully.run(
          receiver: customer,
          customer_payment: payment
        )
      end

      if Rails.configuration.x.env.production?
        HiJob.set(wait_until: 5.minutes.from_now).perform_later("[OK] 🎉Sale Page #{sale_page.slug} customer_id: #{customer.id} Stripe charge💰")
      end
    rescue Stripe::CardError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.auth_failed!
      errors.add(:customer, :auth_failed)

      failed_charge_notification(payment)

      Rollbar.error(error, toruya_service_charge: online_service_customer_relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue Stripe::StripeError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.processor_failed!
      errors.add(:customer, :processor_failed)

      failed_charge_notification(payment)

      Rollbar.error(error, toruya_service_charge: online_service_customer_relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue => e
      Rollbar.error(e)
      errors.add(:customer, :something_wrong)
    end

    payment
  end

  private

  def failed_charge_notification(payment)
    unless manual
      Notifiers::CustomerPayments::ChargeFailedToOwner.run(
        receiver: customer.user,
        customer_payment: payment
      )

      Notifiers::CustomerPayments::ChargeFailedToCustomer.run(
        receiver: customer,
        customer_payment: payment
      )
    end
  end

  def sale_page
    @sale_page ||= online_service_customer_relation.sale_page
  end

  def customer
    @customer ||= online_service_customer_relation.customer
  end

  def online_service
    @online_service ||= online_service_customer_relation.online_service
  end

  def validate_online_service_customer_relation_state
    if online_service_customer_relation.paid_payment_state?
      errors.add(:online_service_customer_relation, :was_paid)
    end
  end
end
