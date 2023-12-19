# frozen_string_literal: true

module CustomerPayments
  class All < ActiveInteraction::Base
    object :customer

    def execute
      customer.customer_payments.payment_type.order(id: :desc)
    end
  end
end
