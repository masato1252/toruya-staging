module Subscriptions
  class Charge < ActiveInteraction::Base
    object :user
    object :plan
    boolean :manual

    def execute
      SubscriptionCharge.transaction do
        charge = user.subscription_charges.create!(
          plan: plan,
          amount: Money.new(plan.cost, Money.default_currency.id),
          charge_date: Subscription.today,
          manual: manual
        )

        begin
          stripe_charge = Stripe::Charge.create({
            amount: plan.cost,
            currency: Money.default_currency.iso_code,
            customer: user.subscription.stripe_customer_id,
            description: plan.level,
            statement_descriptor: plan.level,
            metadata: {
              charge_id: charge.id,
              level: plan.level,
              user_id: user.id
            }
          })
          charge.stripe_charge_details = stripe_charge.as_json
          charge.order_id = SecureRandom.hex(6).upcase
          charge.completed!
        rescue Stripe::CardError, Stripe::StripeError => error
          Rollbar.error(error, charge: charge.id)

          charge.charge_failed!
          SubscriptionMailer.charge_failed(user.subscription).deliver_now unless manual
          errors.add(:plan, :charge_failed)
        end

        charge
      end
    end
  end
end
