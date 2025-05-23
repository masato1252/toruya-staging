# frozen_string_literal: true

module Plans
  class Subscribe < ActiveInteraction::Base
    object :user
    object :plan
    integer :rank
    string :authorize_token, default: nil # downgrade plan and upgrade later don't need this.
    boolean :change_immediately, default: true
    string :payment_intent_id, default: nil

    def execute
      subscription = user.subscription

      if subscription.active? && subscription.current_plan == plan
        errors.add(:plan, :already_subscribe_the_same_plan)
        return
      end

      # XXX: There is no reasn to downgrade immediately, upgrade or become to same level's plan could be changed immediately
      if !subscription.current_plan.downgrade?(plan) && change_immediately
        compose(
          Subscriptions::ManualCharge,
          subscription: subscription,
          plan: plan,
          rank: rank,
          authorize_token: authorize_token,
          payment_intent_id: payment_intent_id
        )
      else
        # change plan later
        subscription.update(next_plan: plan)
      end
    end
  end
end
