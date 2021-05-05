# frozen_string_literal: true

module Subscriptions
  class Bonus < ActiveInteraction::Base
    object :subscription
    object :plan, default: nil
    integer :rank, default: nil
    date :expired_date
    string :reason

    validate :validate_expired_date

    def execute
      subscription.with_lock do
        order_id = SecureRandom.hex(8).upcase

        user = subscription.user
        charge = user.subscription_charges.create!(
          plan: plan || subscription.plan,
          rank: rank || subscription.rank,
          amount: Money.zero,
          charge_date: Subscription.today,
          expired_date: expired_date,
          manual: false,
          state: :bonus,
          order_id: order_id,
          details: {
            reason: reason
          }
        )

        subscription.plan = plan if plan
        subscription.rank = rank if rank
        subscription.recurring_day = expired_date.day
        subscription.expired_date = expired_date
        subscription.save!
      end
    end

    private

    def validate_expired_date
      if subscription.expired_date > expired_date
        errors.add(:expired_date, :invalid)
      end
    end
  end
end
