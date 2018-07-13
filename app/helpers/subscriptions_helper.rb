module SubscriptionsHelper
  def subscription_status(subscription)
    if subscription.active?
      "Active"
    else
      "#{subscription.plan.name} expired"
    end
  end
end
