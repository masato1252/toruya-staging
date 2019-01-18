namespace :subscriptions do
  task :charge => :environment do
    today = Subscription.today

    Subscription.charge_required.recurring_chargeable_at(today).chargeable(today).find_each do |subscription|
      SubscriptionChargeJob.perform_later(subscription)
    end

    Slack::Web::Client.new.chat_postMessage(channel: 'development', text: "[OK] subscription charge") if Rails.env.production?
  end

  task :charge_reminder => :environment do
    seven_days_later = Subscription.today.advance(days: 7)

    Subscription.charge_required.recurring_chargeable_at(seven_days_later).chargeable(seven_days_later).find_each do |subscription|
      SubscriptionMailer.charge_reminder(subscription).deliver_later
    end

    Slack::Web::Client.new.chat_postMessage(channel: 'development', text: "[OK] subscription charge reminder") if Rails.env.production?
  end

  task :trial_member_reminder => :environment do
    today = Subscription.today

    scope = User.joins(:subscription).where("users.created_at >= ?", Plan::TRIAL_PLAN_THRESHOLD_MONTHS.months.ago)
    scope.where("subscriptions.plan_id = ?", Subscription::FREE_PLAN_ID).or(
      scope.where("subscriptions.expired_date < ?", today)
    ).find_each do |user|
      after_signup_days = (today - user.created_at.to_date).to_i
      before_trial_expired_days = (user.trial_expired_date - today).to_i

      if after_signup_days == 30
        ReminderMailer.trial_member_months_ago_reminder(user, 2).deliver_later
      elsif after_signup_days == 60
        ReminderMailer.trial_member_months_ago_reminder(user, 1).deliver_later
      elsif before_trial_expired_days == 7
        ReminderMailer.trial_member_week_ago_reminder(user).deliver_later
      elsif before_trial_expired_days == 1
        ReminderMailer.trial_member_day_ago_reminder(user).deliver_later
      end
    end

    Slack::Web::Client.new.chat_postMessage(channel: 'development', text: "[OK] subscription trial_member_reminder") if Rails.env.production?
  end
end
