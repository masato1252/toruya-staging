# frozen_string_literal: true

module Subscriptions
  class Unsubscribe < ActiveInteraction::Base
    object :user

    def execute
      user.subscription.update(plan_id: Subscription::FREE_PLAN_ID, rank: 0, next_plan: nil)
    end
  end
end
