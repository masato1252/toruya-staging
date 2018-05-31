module Plans
  class Subscribe < ActiveInteraction::Base
    object :user
    object :plan
    string :authorize_token, default: nil # free plan don't need this.

    def execute
      if subscription = user.subscription
        errors.add(:plan, :already_subscribe_the_same_plan) if subscription.active? && subscription.plan.become(plan).zero?
        return
      else
        subscription = user.build_subscription
      end

      if subscription.new_record?
        if plan.cost.zero?
          subscription.update(plan: plan)
        else
          compose(Subscriptions::ManualCharge, subscription: subscription, plan: plan, authorize_token: authorize_token)
        end
      else
        if subscription.plan.become(plan).positive?
          # upgrade
          compose(Subscriptions::ManualCharge, subscription: subscription, plan: plan, authorize_token: authorize_token)
        else
          # downgrade
          subscription.update(next_plan: plan)
        end
      end
    end
  end
end
