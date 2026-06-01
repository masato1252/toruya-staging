# frozen_string_literal: true

module Subscriptions
  class ShopFeeProration < ActiveInteraction::Base
    object :user
    integer :shop_count, default: 1

    def execute
      monthly = per_shop_monthly_fee
      subscription = user.subscription

      unless subscription&.in_paid_plan?
        return proration_result(monthly, monthly, period_start: Subscription.today, period_end: Subscription.today.end_of_month)
      end

      unless subscription.expired_date
        return proration_result(monthly, monthly, period_start: Subscription.today, period_end: Subscription.today.end_of_month)
      end

      period_start = Subscription.today
      period_end = subscription.expired_date - 1.day
      total_days = billing_period_days(subscription)
      remaining_days = subscription.expired_date - Subscription.today

      prorated = if total_days.positive? && remaining_days.positive?
        monthly * Rational(remaining_days, total_days)
      else
        monthly
      end

      # Never charge more than one-month fee for immediate proration.
      prorated = [prorated, monthly].min

      proration_result(prorated, monthly, period_start: period_start, period_end: period_end)
    end

    private

    def per_shop_monthly_fee
      Money.new(Plans::Fee::PER_SHOP_FEE.fetch(user.currency) * shop_count, user.currency)
    end

    def billing_period_days(subscription)
      subscription.expired_date - billing_period_start(subscription)
    end

    def billing_period_start(subscription)
      prev_month_date = subscription.expired_date.prev_month
      year = prev_month_date.year
      month = prev_month_date.month
      end_day_of_month = Date.new(year, month, -1).day
      recurring_day = subscription.recurring_day || subscription.expired_date.day
      day = [[recurring_day, 1].max, end_day_of_month].min

      Date.new(year, month, day)
    end

    def proration_result(amount, monthly, period_start:, period_end:)
      {
        amount: amount,
        monthly_fee: monthly,
        period_start: period_start,
        period_end: period_end
      }
    end
  end
end
