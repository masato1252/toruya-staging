# frozen_string_literal: true

class CustomerPayments::ChangeServiceExpireAt < ActiveInteraction::Base
  object :online_service_customer_relation
  time :expire_at, default: nil
  string :memo, default: nil

  def execute
    if online_service.bundler?
      bundled_online_service_ids = online_service.bundled_services.pluck(:online_service_id)

      OnlineServiceCustomerRelation.where(online_service_id: bundled_online_service_ids, customer_id: online_service_customer_relation.customer_id).each do |relation|
        compose(CustomerPayments::ChangeServiceExpireAt, online_service_customer_relation: relation, memo: memo)
      end
    end

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

  def online_service
    @online_service ||= online_service_customer_relation.online_service
  end
end
