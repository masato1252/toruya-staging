module SubscriptionsHelper
  def subscription_status(subscription)
    if subscription.active?
      status = t("settings.subscription.status.active")

      if subscription.next_plan
        status << " (#{subscription.next_plan.name} from #{l(subscription.expired_date.tomorrow)})"
      end

      status
    else
      "#{subscription.plan.name} expired"
    end
  end
end
