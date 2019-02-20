module Subscriptions
  class Charge < ActiveInteraction::Base
    object :user
    object :plan
    boolean :manual
    object :charge_amount, class: Money, default: nil
    string :charge_description, default: nil

    def execute
      SubscriptionCharge.transaction do
        order_id = Digest::SHA1.hexdigest("#{Time.now.to_i}:#{user.id}:#{user.subscription_charges.count}:#{SecureRandom.hex(16)}").first(16).upcase
        amount = charge_amount || compose(Plans::Price, user: user, plan: plan)
        description = charge_description || plan.level

        charge = user.subscription_charges.create!(
          plan: plan,
          amount: amount,
          charge_date: Subscription.today,
          manual: manual,
          order_id: order_id
        )

        begin
          stripe_charge = Stripe::Charge.create({
            amount: amount.fractional,
            currency: Money.default_currency.iso_code,
            customer: user.subscription.stripe_customer_id,
            description: description,
            statement_descriptor: "Toruya charge #{description}",
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

          if Rails.configuration.x.env.production?
            Slack::Web::Client.new.chat_postMessage(channel: 'development', text: "[OK] 🎉Subscription Stripe charge💰")
          end
        rescue Stripe::CardError => error
          charge.auth_failed!
          errors.add(:plan, :auth_failed)

          SubscriptionMailer.charge_failed(user.subscription, charge).deliver_now unless manual

          Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error])
        rescue Stripe::StripeError => error
          charge.processor_failed!
          errors.add(:plan, :processor_failed)

          SubscriptionMailer.charge_failed(user.subscription, charge).deliver_now unless manual

          Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error])
        rescue => e
          Rollbar.error(e)
          errors.add(:plan, :something_wrong)
        end

        charge
      end
    end
  end
end
