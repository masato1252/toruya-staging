namespace :subscriptions do
  task :charge => :environment do
    today = Subscription.today

    Subscription.charge_required.recurring_chargeable_at(today).chargeable(today).find_each do |subscription|
      SubscriptionChargeJob.perform_later(subscription)
    end
  end

  task :charge_reminder => :environment do
    seven_days_later = Subscription.today.advance(days: 7)

    Subscription.charge_required.recurring_chargeable_at(seven_days_later).chargeable(seven_days_later).find_each do |subscription|
      SubscriptionMailer.charge_reminder(subscription).deliver_later
    end
  end
end
