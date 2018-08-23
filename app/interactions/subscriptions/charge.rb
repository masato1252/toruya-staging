module Subscriptions
  class Charge < ActiveInteraction::Base
    object :user
    object :plan
    boolean :manual

    def execute
      SubscriptionCharge.transaction do
        order_id = Digest::SHA1.hexdigest("#{Time.now.to_i}:#{user.id}:#{user.subscription_charges.count}:#{SecureRandom.hex(16)}").first(16).upcase
        charge_amount = Plans::Price.run!(user: user, plan: plan)

        charge = user.subscription_charges.create!(
          plan: plan,
          amount: charge_amount,
          charge_date: Subscription.today,
          manual: manual,
          order_id: order_id
        )

        begin
          stripe_charge = Stripe::Charge.create({
            amount: charge_amount.fractional,
            currency: Money.default_currency.iso_code,
            customer: user.subscription.stripe_customer_id,
            description: plan.level,
            statement_descriptor: plan.level,
            metadata: {
              charge_id: charge.id,
              level: plan.level,
              user_id: user.id,
              order_id: order_id
            }
          })

          # credit card charge is synchronous request, it would return final status immediately
          charge.stripe_charge_details = stripe_charge.as_json
          charge.completed!
        rescue Stripe::CardError => error
          Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error][:charge])

          charge.auth_failed!
          errors.add(:plan, :auth_failed)

          SubscriptionMailer.charge_failed(user.subscription, charge).deliver_now unless manual
        rescue Stripe::StripeError => error
          Rollbar.error(error, toruya_charge: charge.id)

          charge.processor_failed!
          errors.add(:plan, :processor_failed)

          SubscriptionMailer.charge_failed(user.subscription, charge).deliver_now unless manual
        end

        charge
      end
    end
  end
end
