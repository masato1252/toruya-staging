module Plans
  class Subscribe < ActiveInteraction::Base
    object :user
    object :plan
    string :authorize_token, default: nil # free plan and upgrade later don't need this.
    boolean :upgrade_immediately, default: true

    def execute
      subscription = user.subscription

      if subscription.active? && subscription.current_plan.become(plan).zero?
        errors.add(:plan, :already_subscribe_the_same_plan)
        return
      end

      if subscription.current_plan.become(plan).positive? && upgrade_immediately
        # upgrade immediately
        compose(Subscriptions::ManualCharge, subscription: subscription, plan: plan, authorize_token: authorize_token)
      else
        # downgrade/upgrade later
        subscription.update(next_plan: plan)
      end
    end
  end
end
