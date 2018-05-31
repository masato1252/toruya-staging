module Subscriptions
  class ManualCharge < ActiveInteraction::Base
    object :subscription
    object :plan
    string :authorize_token

    def execute
      subscription.transaction do
        subscription.plan = plan
        user = subscription.user

        charge = user.subscription_charges.create!(
          user: user,
          plan: plan,
          amount: Money.new(plan.cost, Money.default_currency.id),
          charge_date: Subscription.today,
          manual: true
        )
        stripe_customer_id = compose(Payments::StoreStripeCustomer, user: user, authorize_token: authorize_token)

        Stripe::Charge.create({
          amount: plan.cost,
          currency: Money.default_currency.iso_code,
          customer: stripe_customer_id,
        })

        charge.completed!
        subscription.set_recurring_day
        subscription.set_expire_date
      end
    end
  end
end
