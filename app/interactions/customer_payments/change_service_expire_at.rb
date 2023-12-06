# frozen_string_literal: true

class CustomerPayments::ChangeServiceExpireAt < ActiveInteraction::Base
  object :online_service_customer_relation
  time :expire_at, default: nil
  string :memo, default: nil

  def execute
    online_service_customer_relation.with_lock do
      customer.customer_payments.create!(
        product: online_service_customer_relation,
        amount: nil,
        charge_at: nil,
        expired_at: expire_at,
        manual: true,
        state: :change_expire_at,
        memo: memo
      )

      online_service_customer_relation.update!(expire_at: expire_at)
    end
  end

  private

  def customer
    @customer ||= online_service_customer_relation.customer
  end
end
