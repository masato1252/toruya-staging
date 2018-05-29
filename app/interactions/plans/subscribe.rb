module Plans
  class Subscribe < ActiveInteraction::Base
    object :user
    object :plan
    string :authorize_token

    def execute
      if subscription = user.subscription
        errors.add(:plan, :already_subscribe_the_same_plan) if subscription.active? && subscription.plan_id == plan.id
        return
      else
        subscription = user.build_subscription
        subscription.pending!
      end

      subscription.transaction do
        subscription.plan = plan

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
        subscription.active!
      end
    end
  end
end
