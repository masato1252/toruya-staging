module Plans
  class Price < ActiveInteraction::Base
    object :user
    object :plan

    def execute
      plan.cost_with_currency + compose(Plans::Fee, user: user, plan: plan)
    end
  end
end
