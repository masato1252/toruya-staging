module SubscriptionsHelper
  def subscription_status(subscription)
    if subscription.active?
      t("settings.subscription.status.active")
    else
      "#{subscription.plan.name} #{t("settings.subscription.status.expired")}"
    end
  end
end
