# frozen_string_literal: true

module Notifiers
  module Users
    module Reminders
      class ReachCustomersLimit < Base
        deliver_by_priority [:line, :sms, :email]

        def message
          if receiver.subscription.plan.free_level?
            I18n.t("notifier.reminders.free_plan_reach_customers_limit.message", user_name: receiver.name)
          elsif receiver.subscription.rank == Plan.max_legal_rank
            I18n.t("notifier.reminders.paid_plan_reach_whole_customers_limit.message", user_name: receiver.name)
          else
            I18n.t("notifier.reminders.paid_plan_reach_customers_limit.message", user_name: receiver.name, next_max_customer_limit: Plan.max_customers_limit(receiver.subscription.plan.level, receiver.subscription.rank + 1), user_last_name: receiver.profile.last_name || receiver.profile.phonetic_last_name)
          end
        end
      end
    end
  end
end
