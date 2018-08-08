namespace :subscriptions do
  task :charge => :environment do
    today = Subscription.today

    if ENV["PRODUCTION_ENV"] == "staging"
      Subscription.charge_required.find_each do |subscription|
        SubscriptionChargeJob.perform_later(subscription)
      end
    else
      Subscription.charge_required.recurring_chargeable_at(today).chargeable(today).find_each do |subscription|
        SubscriptionChargeJob.perform_later(subscription)
      end
    end
  end

  task :charge_reminder => :environment do
    seven_days_later = Subscription.today.advance(days: 7)

    if ENV["PRODUCTION_ENV"] == "staging"
      Subscription.charge_required.find_each do |subscription|
        SubscriptionMailer.charge_reminder(subscription).deliver_later
      end
    else
      Subscription.charge_required.recurring_chargeable_at(seven_days_later).chargeable(seven_days_later).find_each do |subscription|
        SubscriptionMailer.charge_reminder(subscription).deliver_later
      end
    end
  end
end
