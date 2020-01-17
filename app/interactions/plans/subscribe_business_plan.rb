module Plans
  class SubscribeBusinessPlan < ActiveInteraction::Base
    object :user
    string :authorize_token

    validate :validate_user

    def execute
      # XXX: Business plan need to be charged immediately because we need to charge registration fee
      compose(Plans::Subscribe, user: user, plan: Plan.business_level.take, authorize_token: authorize_token)
    end

    private

    def validate_user
      if user.business_member?
        errors.add(:user, :invalid_plan)
      end
    end
  end
end
