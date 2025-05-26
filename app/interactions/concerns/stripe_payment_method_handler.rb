# frozen_string_literal: true

module StripePaymentMethodHandler
  extend ActiveSupport::Concern

  private

  # Get payment method with priority order:
  # 1. Use payment method ID from frontend (if provided)
  # 2. Use customer's default payment method
  # 3. Use latest attached payment method
  def get_selected_payment_method(stripe_customer_id, payment_method_id = nil, stripe_account = nil)
    if payment_method_id.present?
      # Ensure the payment method is attached to the customer
      begin
        # First, try to attach the payment method to the customer if it's not already attached
        attach_payment_method_to_customer(payment_method_id, stripe_customer_id, stripe_account)
        payment_method_id
      rescue Stripe::StripeError => e
        # If we can't attach the payment method, fall back to customer's default
        Rollbar.error(e,
          stripe_customer_id: stripe_customer_id,
          payment_method_id: payment_method_id,
          context: 'attach_payment_method'
        )

        get_customer_default_payment_method(stripe_customer_id, stripe_account)
      end
    else
      get_customer_default_payment_method(stripe_customer_id, stripe_account)
    end
  end

  # Attach payment method to customer, handling already attached case
  def attach_payment_method_to_customer(payment_method_id, stripe_customer_id, stripe_account = nil)
    begin
      if stripe_account
        Stripe::PaymentMethod.attach(
          payment_method_id,
          { customer: stripe_customer_id },
          stripe_account: stripe_account
        )
      else
        Stripe::PaymentMethod.attach(
          payment_method_id,
          { customer: stripe_customer_id }
        )
      end
    rescue Stripe::InvalidRequestError => e
      # If it's already attached, that's fine, continue
      if !e.message.include?("already been attached")
        raise e
      end
    end
  end

  # Get customer's default payment method or latest attached payment method
  def get_customer_default_payment_method(stripe_customer_id, stripe_account = nil)
    begin
      if stripe_account
        customer = Stripe::Customer.retrieve(stripe_customer_id, stripe_account: stripe_account)
      else
        customer = Stripe::Customer.retrieve(stripe_customer_id)
      end

      customer.invoice_settings&.default_payment_method ||
        get_latest_payment_method(stripe_customer_id, stripe_account)
    rescue Stripe::StripeError => e
      Rollbar.error(e, stripe_customer_id: stripe_customer_id, context: 'get_customer_default_payment_method')
      nil
    end
  end

  # Get the latest attached payment method for a customer
  def get_latest_payment_method(customer_id, stripe_account = nil)
    begin
      if stripe_account
        payment_methods = Stripe::PaymentMethod.list(
          {
            customer: customer_id,
            type: 'card',
            limit: 1
          },
          stripe_account: stripe_account
        )
      else
        payment_methods = Stripe::PaymentMethod.list({
          customer: customer_id,
          type: 'card',
          limit: 1
        })
      end

      payment_methods.data.first&.id
    rescue Stripe::StripeError => e
      Rollbar.error(e, customer_id: customer_id, context: 'get_latest_payment_method')
      nil
    end
  end
end