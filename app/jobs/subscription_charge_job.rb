class SubscriptionChargeJob < ApplicationJob
  queue_as :urgent

  def perform(subscription)
    Subscriptions::RecurringCharge.run(subscription: subscription)
  end
end
