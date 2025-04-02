# frozen_string_literal: true

require "slack_client"

namespace :notifications do
  # notify pending tasks summary to business owner
  task :pending_tasks => :environment do
    current_time = Time.now.in_time_zone('Tokyo').beginning_of_hour
    hour = current_time.hour

    time_range =
      if hour == 7
        # 17 ~ 7
        current_time.yesterday.change(hour: 17)..current_time
      elsif hour == 17
        # 7 ~ 17
        current_time.change(hour: 7)..current_time
      end

    if time_range
      User.business_active(time_range).find_each do |user|
        Notifiers::Users::PendingTasksSummary.perform_at(
          schedule_at: Time.current.in_time_zone(user.timezone).change(hour: 7, min: 10 + rand(20)),
          receiver: user,
          start_at: time_range.first.to_s,
          end_at: time_range.last.to_s
        )
      end

      SlackClient.send(channel: 'development', text: "[OK] daily notifications task") if Rails.configuration.x.env.production?
    end
  end
end
