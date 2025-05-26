# frozen_string_literal: true

module Customers
  class StorePaymentCustomer < ActiveInteraction::Base
    object :customer
    string :authorize_token
    object :payment_provider, class: AccessProvider
    string :payment_intent_id, default: nil

    validate :validate_payment_providers

    def execute
      case payment_provider.provider
      when AccessProvider.providers[:stripe_connect]
        compose(Customers::StoreStripeCustomer, customer: customer, authorize_token: authorize_token)
      when AccessProvider.providers[:square]
        compose(Customers::StoreSquareCustomer, customer: customer, authorize_token: authorize_token)
      end
    end

    private

    def validate_payment_providers
      if !payment_provider.provider.in?(AccessProvider::PAYMENT_PROVIDERS)
        errors.add(:payment_provider, :invalid)
      end
    end
  end
end
