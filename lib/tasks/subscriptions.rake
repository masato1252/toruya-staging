# frozen_string_literal: true

require "slack_client"

namespace :subscriptions do
  task :charge => :environment do
    today = Subscription.today

    Subscription.charge_required.recurring_chargeable_at(today).chargeable(today).find_each do |subscription|
      SubscriptionChargeJob.perform_later(subscription)
      sleep(0.01)
    end

    SlackClient.send(channel: 'development', text: "[OK] subscription charge task") if Rails.configuration.x.env.production?
  end

  task :charge_reminder => :environment do
    seven_days_later = Subscription.today.advance(days: 7)

    Subscription.charge_required.recurring_chargeable_at(seven_days_later).chargeable(seven_days_later).find_each do |subscription|
      Notifiers::Users::Subscriptions::ChargeReminder.perform_later(
        receiver: subscription.user,
        user: subscription.user,
        subscription: subscription
      )
      sleep(0.01)
    end

    SlackClient.send(channel: 'development', text: "[OK] subscription charge reminder task") if Rails.configuration.x.env.production?
  end

  task :trial_member_reminder => :environment do
    today = Subscription.today

    # scope = User
    #   .joins(:subscription)
    #   .where("subscriptions.trial_expired_date < ? and subscriptions.trial_expired_date > ?", today.advance(days: 8), today)

    # scope.where("subscriptions.plan_id = ?", Subscription::FREE_PLAN_ID).or(
    #   scope.where("subscriptions.expired_date < ?", today)
    # ).find_each do |user|
    #   after_signup_days = (today - user.created_at.to_date).to_i
    #   before_trial_expired_days = (user.trial_expired_date - today).to_i

    #   case before_trial_expired_days
    #   when 7
    #     Notifiers::Users::Reminders::TrialMemberWeekAgoReminder.perform_later(receiver: user, user: user)
    #   when 1
    #     Notifiers::Users::Reminders::TrialMemberDayAgoReminder.perform_later(receiver: user, user: user)
    #   end
    #   sleep(0.01)
    # end

    # change notification channel to email for trial users who was expired in 2 ~ 7 days
    expired_trail_scope = User.joins(:subscription).where("subscriptions.trial_expired_date": today.advance(days: -2)..today.advance(days: -7)).where("subscriptions.plan_id = ?", Subscription::FREE_PLAN_ID)

    expired_trail_scope.find_each do |user|
      if user.user_setting.customer_notification_channel != "email"
        user.user_setting.update(customer_notification_channel: "email")
        Notifiers::Users::Reminders::TrialMemberChangeNotificationChannel.perform_later(receiver: user, user: user)
      end
    end

    SlackClient.send(channel: 'development', text: "[OK] subscription trial_member_reminder task") if Rails.configuration.x.env.production?
  end

  task :renew_payment_access_token => :environment do
    # renew on Monday
    if Time.now.in_time_zone('Tokyo').wday == 1
      AccessProvider.square.find_each do |square_provider|
        AccessProviders::RenewAccessToken.perform_later(access_provider: square_provider)
      end
    end
  end
end
