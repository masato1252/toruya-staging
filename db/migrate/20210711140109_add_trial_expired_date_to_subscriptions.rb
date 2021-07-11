class AddTrialExpiredDateToSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_column :subscriptions, :trial_expired_date, :date

    Subscription.find_each do |subscription|
      subscription.update(
        trial_days: subscription.trial_days ? subscription.trial_days : Plan::TRIAL_PLAN_THRESHOLD_DAYS,
        trial_expired_date: subscription.created_at.advance(days: subscription.trial_days || Plan::TRIAL_PLAN_THRESHOLD_DAYS).to_date
      )
    end
  end
end
