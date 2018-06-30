namespace :subscriptions do
  task :charge => :environment do
    today = Subscription.today

    Subscription.charge_required.recurring_chargeable_at(today).chargeable(today).find_each do |subscription|
      SubscriptionChargeJob.perform_later(subscription)
    end
  end

  task :expired_ard_notification => :environment do
    today = Subscription.today

    Subscription.charge_free.recurring_chargeable_at(today).find_each do |subscription|
      next unless subscription.chargeable?

      # Delayer.enqueue(CreditSubscriptionChargeJob, subscription.id, today)
    end
  end
end
