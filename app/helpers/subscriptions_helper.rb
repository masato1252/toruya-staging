module SubscriptionsHelper
  def subscription_status(subscription)
    sentence = if subscription.active?
      t("settings.subscription.status.active")

      if subscription.next_plan
        sentence << " (#{subscription.next_plan.name} from #{l(subscription.expired_date.tomorrow)})"
      end
    else
      "#{subscription.plan.name} expired"
    end


    sentence
  end
end
