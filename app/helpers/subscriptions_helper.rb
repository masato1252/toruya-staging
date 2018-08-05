module SubscriptionsHelper
  def subscription_status(subscription)
    sentence = if subscription.active?
      "Active"
    else
      "#{subscription.plan.name} expired"
    end

    if subscription.next_plan
      sentence << " (#{subscription.next_plan.name} from #{l(subscription.expired_date.tomorrow)})"
    end

    sentence
  end
end
