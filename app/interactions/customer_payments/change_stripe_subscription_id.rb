# frozen_string_literal: true

class CustomerPayments::ChangeStripeSubscriptionId < ActiveInteraction::Base
  object :online_service_customer_relation
  string :stripe_subscription_id

  def execute
    old_id = online_service_customer_relation.stripe_subscription_id
    new_id = stripe_subscription_id
    online_service_customer_relation.with_lock do
      online_service_customer_relation.customer.customer_payments.create!(
        product: online_service_customer_relation,
        amount: nil,
        charge_at: nil,
        manual: true,
        state: :change_stripe_subscription_id,
        memo: "#{old_id} => #{new_id}"
      )
      online_service_customer_relation.update!(stripe_subscription_id: new_id)
    end
  end
end