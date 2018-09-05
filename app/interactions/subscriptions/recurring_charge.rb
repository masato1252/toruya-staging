module Subscriptions
  class RecurringCharge < ActiveInteraction::Base
    object :subscription

    def execute
      user = subscription.user

      charging_plan = subscription.next_plan || subscription.plan

      if charging_plan.cost.zero?
        subscription.update(plan: charging_plan, next_plan: nil)
      else
        subscription.transaction do
          charge = compose(Subscriptions::Charge, user: user, plan: charging_plan, manual: false)

          subscription.plan = charging_plan
          subscription.next_plan = nil
          subscription.set_expire_date
          subscription.save!

          charge.expired_date = subscription.expired_date
          charge.details ||= {}
          fee = compose(Plans::Fee, user: user, plan: charging_plan)
          charge.details.merge!({
            shop_ids: user.shop_ids,
            shop_fee: fee.fractional,
            shop_fee_format: fee.format,
            type: SubscriptionCharge::TYPES[:plan_subscruption]
          })
          charge.save!

          SubscriptionMailer.charge_successfully(subscription).deliver_now
        end
      end
    end
  end
end
