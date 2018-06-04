module Subscriptions
  class Charge < ActiveInteraction::Base
    object :user
    object :plan
    string :stripe_customer_id
    boolean :manual

    def execute
      SubscriptionCharge.transaction do
        charge = user.subscription_charges.create!(
          user: user,
          plan: plan,
          amount: Money.new(plan.cost, Money.default_currency.id),
          charge_date: Subscription.today,
          manual: manual
        )

        begin
          oo = Stripe::Charge.create({
            amount: plan.cost,
            currency: Money.default_currency.iso_code,
            customer: stripe_customer_id,
          })
          charge.completed!
        rescue Stripe::CardError, Stripe::StripeError => error
          Rollbar.error(error, charge: charge.id)

          charge.charge_failed!
          errors.add(:plan, :charge_failed)
        end

        charge
      end
    end
  end
end
