# frozen_string_literal: true

require "slack_client"

class CustomerPayments::PurchaseOnlineService < ActiveInteraction::Base
  object :online_service_customer_relation
  object :online_service_customer_price, class: OnlineServiceCustomerPrice, default: nil
  boolean :first_time_charge, default: false
  boolean :manual, default: false
  string :payment_intent_id, default: nil

  validate :validate_online_service_customer_relation_state

  def execute
    expire_at = online_service.current_expire_time if first_time_charge
    price_details = online_service_customer_price || online_service_customer_relation.price_details.first
    charging_price_amount = price_details.amount_with_currency

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
      payment_intent = if payment_intent_id.present?
        retrieved_intent = Stripe::PaymentIntent.retrieve(
          payment_intent_id,
          stripe_account: customer.user.stripe_provider.uid
        )

                # If Payment Intent is already succeeded (after 3DS completion),
        # handle the success immediately without recreating
        if retrieved_intent.status == 'succeeded'
          handle_payment_success(payment, retrieved_intent)
          return payment
        end

        retrieved_intent
      else
        # Check if customer has a stripe customer ID
        if customer.stripe_customer_id.blank?
          payment.auth_failed!
          errors.add(:online_service_customer_relation, :no_stripe_customer)
          return payment
        end

        # Get customer's default payment method
        begin
          stripe_customer = Stripe::Customer.retrieve(
            customer.stripe_customer_id,
            stripe_account: customer.user.stripe_provider.uid
          )
          default_payment_method = stripe_customer.invoice_settings&.default_payment_method ||
                                   get_latest_payment_method(customer.stripe_customer_id)
        rescue Stripe::StripeError => e
          payment.auth_failed!
          errors.add(:online_service_customer_relation, :stripe_customer_not_found)
          Rollbar.error(e, customer_id: customer.id, stripe_customer_id: customer.stripe_customer_id)
          return payment
        end

        payment_intent_params = {
          amount: charging_price_amount.fractional * charging_price_amount.currency.default_subunit_to_unit,
          currency: customer.user.currency,
          customer: customer.stripe_customer_id,
          description: sale_page.product_name.first(STRIPE_DESCRIPTION_LIMIT),
          metadata: {
            relation: online_service_customer_relation.id,
            sale_page: sale_page.slug,
            customer_id: customer.id,
            customer_name: customer.name,
            service_id: online_service.id
          },
          setup_future_usage: 'off_session',
          confirmation_method: 'automatic',
          capture_method: 'automatic',
          payment_method_types: ['card'],
        }

        # Add payment method and confirm if available
        if default_payment_method.present?
          payment_intent_params[:payment_method] = default_payment_method
          payment_intent_params[:confirm] = true
        end

        Stripe::PaymentIntent.create(
          payment_intent_params,
          stripe_account: customer.user.stripe_provider.uid
        )
      end

      payment.stripe_charge_details = payment_intent.as_json

      case payment_intent.status
      when 'succeeded'
        handle_payment_success(payment, payment_intent)
      # All statuses that require frontend handling with client_secret:
      # - requires_action: 3DS authentication, redirects, etc.
      # - requires_payment_method: Payment failed, need new payment method
      # - requires_confirmation: Manual confirmation required
      # - requires_source: Legacy API support
      # - requires_source_action: Legacy API support
      # - processing: Payment submitted but not yet complete (some payment methods)
      when 'requires_action', 'requires_payment_method', 'requires_confirmation', "requires_source", "processing", "requires_source_action"
        payment.stripe_charge_details = payment_intent.as_json
        payment.save!
        errors.add(:online_service_customer_relation, :requires_action, client_secret: payment_intent.client_secret, payment_intent_id: payment_intent.id)
      when 'canceled'
        payment.auth_failed!
        errors.add(:online_service_customer_relation, :canceled)
      else
        Rollbar.error("Payment intent failed", status: payment_intent.status, toruya_charge: payment.id, stripe_charge: payment_intent.as_json)
        payment.auth_failed!
        errors.add(:online_service_customer_relation, :failed)
      end

    rescue Stripe::CardError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.auth_failed!
      errors.add(:online_service_customer_relation, :auth_failed)

      failed_charge_notification(payment)

      Rollbar.error(error, toruya_service_charge: online_service_customer_relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue Stripe::StripeError => error
      payment.stripe_charge_details = error.json_body[:error]
      payment.processor_failed!
      errors.add(:online_service_customer_relation, :processor_failed)

      failed_charge_notification(payment)

      Rollbar.error(error, toruya_service_charge: online_service_customer_relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue => e
      Rollbar.error(e)
      errors.add(:online_service_customer_relation, :something_wrong)
    end

    payment
  end

  private

  def handle_payment_success(payment, payment_intent)
    payment.stripe_charge_details = payment_intent.as_json
    payment.completed!

    if online_service_customer_relation.paid_completed?
      online_service_customer_relation.paid_payment_state!
    else
      online_service_customer_relation.partial_paid_payment_state!
    end

    unless first_time_charge
      Notifiers::Customers::CustomerPayments::NotFirstTimeChargeSuccessfully.run(
        receiver: customer,
        customer_payment: payment
      )
    end

    if Rails.configuration.x.env.production?
      HiJob.set(wait_until: 5.minutes.from_now).perform_later("[OK] 🎉Sale Page #{Rails.application.routes.url_helpers.sale_page_url(sale_page.slug)} customer_id: #{customer.id} Stripe charge💰")
    end
  end

  def failed_charge_notification(payment)
    unless manual
      Notifiers::Users::CustomerPayments::ChargeFailedToOwner.run(
        receiver: customer.user,
        customer_payment: payment
      )

      Notifiers::Customers::CustomerPayments::ChargeFailedToCustomer.run(
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
