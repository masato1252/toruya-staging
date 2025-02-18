# frozen_string_literal: true

module Notifiers
  module Users
    module Reminders
      class CloseCustomersLimit < Base
        deliver_by_priority [:line, :sms, :email]

        def message
          if receiver.subscription.plan.free_level?
            I18n.t("notifier.reminders.free_plan_close_customers_limit.message", user_name: receiver.name, max_customers_limit: Plan.max_customers_limit(Plan::FREE_PLAN, receiver.subscription.rank))
          else
            I18n.t("notifier.reminders.paid_plan_close_customers_limit.message", user_name: receiver.name, current_max_customer_limit: Plan.max_customers_limit(receiver.subscription.plan.level, receiver.subscription.rank), next_max_customer_limit: Plan.max_customers_limit(receiver.subscription.plan.level, receiver.subscription.rank + 1))
          end
        end
      end
    end
  end
end
