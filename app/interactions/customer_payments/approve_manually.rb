# frozen_string_literal: true

class CustomerPayments::ApproveManually < ActiveInteraction::Base
  object :online_service_customer_relation

  def execute
    customer.customer_payments.create!(
      product: online_service_customer_relation,
      amount: nil,
      charge_at: nil,
      expired_at: online_service_customer_relation.expire_at,
      manual: true,
      state: :manually_approved
    )
  end

  private

  def customer
    @customer ||= online_service_customer_relation.customer
  end
end
