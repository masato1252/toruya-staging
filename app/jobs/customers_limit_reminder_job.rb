# frozen_string_literal: true

class CustomersLimitReminderJob < ApplicationJob
  GAP_TO_LIMIT = 10

  queue_as :default

  def perform(user)
    max_customers_limit = Plan.max_customers_limit(user.subscription.plan.level, user.subscription.rank)

    if user.customers.size == max_customers_limit
      Notifiers::Reminders::ReachCustomersLimit.perform_later(receiver: user, user: user)
    elsif user.customers.size == max_customers_limit - GAP_TO_LIMIT
      Notifiers::Reminders::CloseCustomersLimit.perform_later(receiver: user, user: user)
    end
  end
end
