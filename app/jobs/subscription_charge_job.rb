class SubscriptionChargeJob < ApplicationJob
  queue_as :urgent
  after_perform :notify_admin

  def perform(subscription)
    Subscriptions::RecurringCharge.run!(subscription: subscription)
  end

  private

  def notify_admin
    # indeed run this
  end
end
