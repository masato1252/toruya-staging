module Plans
  class SubscribeChildPlan < ActiveInteraction::Base
    object :user
    object :plan
    string :authorize_token, default: nil # downgrade plan and upgrade later don't need this.
    boolean :change_immediately, default: true

    validate :validate_user
    validate :validate_plan

    def execute
      referral = Referral.enabled.find_by!(referrer: user)

      referral.with_lock do
        compose(Plans::Subscribe, user: user, plan: plan, authorize_token: authorize_token, change_immediately: change_immediately)
      end
    end

    private

    def validate_user
      if Referral.enabled.where(referrer: user).empty?
        errors.add(:user, :invalid_referral)
      end
    end

    def validate_plan
      if Plan.where(level: Plan::CHILD_PLANS).exclude?(plan)
        errors.add(:plan, :invalid_plan)
      end
    end
  end
end
