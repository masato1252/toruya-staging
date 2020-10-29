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
            type: plan.business_level? ? SubscriptionCharge::TYPES[:business_member_sign_up] : SubscriptionCharge::TYPES[:plan_subscruption],
            user_name: user.name,
            user_email: user.email,
            pure_plan_amount: compose(Plans::Price, user: user, plan: plan).format,
            plan_amount: compose(Plans::Price, user: user, plan: plan, with_business_signup_fee: true).format,
            plan_name: plan.name
          }
          charge.save!

          Notifiers::Subscriptions::ChargeSuccessfully.run(receiver: subscription.user, user: subscription.user)
        else
          errors.merge!(charge_outcome.errors)
        end
      end
    end
  end
end
