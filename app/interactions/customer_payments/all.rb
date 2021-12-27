# frozen_string_literal: true

module CustomerPayments
  class All < ActiveInteraction::Base
    object :customer

    def execute
      customer.customer_payments.order(id: :desc)
    end
  end
end
