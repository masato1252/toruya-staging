module Notifiers
  module Subscriptions
    class ChargeFailed < Base
      deliver_by_priority [:line, :sms, :email]

      object :subscription_charge

      def message
        I18n.t(
          "notifier.subscriptions.charge_failed.message",
          user_name: user.name,
          plan_name: charging_plan.name,
          charge_date: I18n.l(next_period.first, format: :year_month_date),
          period_start: I18n.l(next_period.first, format: :year_month_date),
          period_end: I18n.l(next_period.last, format: :year_month_date),
          cost: cost
        )
      end

      def send_email
        SubscriptionMailer.charge_failed(subscription, subscription_charge).deliver_now
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
        @cost ||= subscription_charge.amount.format
      end
    end
  end
end
