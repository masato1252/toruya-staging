module Subscriptions
  class Charge < ActiveInteraction::Base
    object :user
    object :plan
    boolean :manual
    object :charge_amount, class: Money, default: nil
    string :charge_description, default: nil

    def execute
      SubscriptionCharge.transaction do
        order_id = SecureRandom.hex(8).upcase
        # XXX: business plan charged manually means, it is a registration charge, user need to pay extra signup fee
        amount = charge_amount || compose(Plans::Price, user: user, plan: plan, with_shop_fee: true, with_business_signup_fee: manual)
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
            statement_descriptor: "Toruya #{description}",
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
          charge.stripe_charge_details = error.json_body[:error]
          charge.auth_failed!
          errors.add(:plan, :auth_failed)

          unless manual
            Notifiers::Subscriptions::ChargeFailed.run(
              receiver: user,
              user: user,
              subscription_charge: charge
            )
          end

          Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
        rescue Stripe::StripeError => error
          charge.stripe_charge_details = error.json_body[:error]
          charge.processor_failed!
          errors.add(:plan, :processor_failed)

          unless manual
            Notifiers::Subscriptions::ChargeFailed.run(
              receiver: user,
              user: user,
              subscription_charge: charge
            )
          end

          Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
        rescue => e
          Rollbar.error(e)
          errors.add(:plan, :something_wrong)
        end

        # XXX: Put the fee and referral behviors here is because the of plans changes behaviors
        # might not happen right away, it might happend in next charge,
        # so Subscriptions::Charge is the place, every charge hehavior will called.
        # So put it here to handle all kind of charge or plan changes.
        if charge.completed? && referral = Referral.enabled.find_by(referrer: user)
          compose(Referrals::ReferrerCharged, charge: charge, referral: referral, plan: plan)
        end

        charge
      end
    end
  end
end
