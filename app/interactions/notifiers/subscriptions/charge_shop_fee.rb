module Notifiers
  module Subscriptions
    class ChargeShopFee < Base
      deliver_by_priority [:line, :sms, :email]

      object :subscription_charge

      def message
        I18n.t(
          "notifier.subscriptions.charge_shop_fee.message",
          user_name: user.name,
          plan_name: charging_plan.name,
          charge_date: I18n.l(subscription_charge.charge_date, format: :year_month_date),
          charge_amount: subscription_charge.amount.format,
          charge_date_at: I18n.l(next_period.first, format: :year_month_date),
          period_start: I18n.l(next_period.first, format: :year_month_date),
          period_end: I18n.l(next_period.last, format: :year_month_date),
          cost: cost
        )
      end

      def send_email
        SubscriptionMailer.charge_shop_fee(subscription, subscription_charge).deliver_now
      end

      private

      def charging_plan
        @charging_plan ||= subscription.next_plan || subscription.plan
      end

      def subscription
        @subscription ||= user.subscription
      end

      def next_period
        @next_period ||= subscription.next_period
      end

      def cost
        @cost ||= Plans::Price.run!(user: user, plan: charging_plan, with_shop_fee: true).format
      end
    end
  end
end
