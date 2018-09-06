module Plans
  class Price < ActiveInteraction::Base
    object :user
    object :plan
    boolean :ignore_fee, default: false

    def execute
      plan.cost_with_currency + (ignore_fee ? 0 : compose(Plans::Fee, user: user, plan: plan))
    end
  end
end
