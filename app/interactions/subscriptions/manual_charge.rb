module Subscriptions
  class ManualCharge < ActiveInteraction::Base
    object :subscription
    object :plan
    string :authorize_token

    def execute
      user = subscription.user

      subscription.with_lock do
        compose(Payments::StoreStripeCustomer, user: user, authorize_token: authorize_token)
        charge_outcome = Subscriptions::Charge.run(user: user, plan: plan, manual: true)

        if charge_outcome.valid?
          charge = charge_outcome.result
          subscription.plan = plan
          subscription.next_plan = nil
          subscription.set_recurring_day
          subscription.set_expire_date
          subscription.save!

          charge.expired_date = subscription.expired_date
          fee = compose(Plans::Fee, user: user, plan: plan)
          charge.details = {
            shop_ids: user.shop_ids,
            shop_fee: fee.fractional,
            shop_fee_format: fee.format,
            type: SubscriptionCharge::TYPES[:plan_subscruption],
            user_name: user.name,
            user_email: user.email,
            plan_amount: plan.cost_with_currency.format,
            plan_name: plan.name
          }
          charge.save!

          SubscriptionMailer.charge_successfully(subscription).deliver_now
        else
          errors.merge!(charge_outcome.errors)
        end
      end
    end
  end
end
