# frozen_string_literal: true

module Users
  class BuildDefaultData < ActiveInteraction::Base
    object :user

    def execute
      user.referral_token ||= Devise.friendly_token[0,5]
      user.public_id ||= SecureRandom.uuid

      unless user.ranks.exists?
        user.ranks.build(name: "VIP", key: Rank::VIP_KEY)
        user.ranks.build(name: I18n.t("constants.rank.regular"), key: Rank::REGULAR_KEY)
      end

      unless user.subscription
        user.build_subscription(
          plan: Plan.free_level.take,
          trial_days: Plan::TRIAL_PLAN_THRESHOLD_DAYS,
          trial_expired_date: Time.current.advance(days: Plan::TRIAL_PLAN_THRESHOLD_DAYS).to_date
        )
      end

      unless user.user_metric
        user.build_user_metric
      end

      unless user.user_setting
        user.build_user_setting
      end
    end
  end
end
