module Users
  class BuildDefaultData < ActiveInteraction::Base
    object :user

    def execute
      unless user.ranks.exists?
        user.ranks.build(name: "VIP", key: Rank::VIP_KEY)
        user.ranks.build(name: I18n.t("constants.rank.regular"), key: Rank::REGULAR_KEY)
      end

      unless user.subscription
        user.build_subscription(plan: Plan.free_level.take)
      end
    end
  end
end
