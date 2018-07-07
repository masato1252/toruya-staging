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
          manual: manual,
          order_id: SecureRandom.hex(6).upcase
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

          # credit card charge is synchronous request, it would return final status immediately
          if stripe_charge.status == "succeeded"
            charge.stripe_charge_details = stripe_charge.as_json
            charge.completed!
          end
        rescue Stripe::CardError => error
          Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error][:charge])

          charge.auth_failed!
          errors.add(:plan, :auth_failed)

          SubscriptionMailer.charge_failed(user.subscription).deliver_now unless manual
        rescue Stripe::StripeError => error
          Rollbar.error(error, toruya_charge: charge.id)

          charge.processor_failed!
          errors.add(:plan, :processor_failed)

          SubscriptionMailer.charge_failed(user.subscription).deliver_now unless manual
        end

        charge
      end
    end
  end
end
