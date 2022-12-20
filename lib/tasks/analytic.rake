# frozen_string_literal: true

require "slack_client"

namespace :analytic do
  task :landing_page_visit => :environment do
    prev_week = Time.now.in_time_zone('Tokyo').prev_week
    start_time = prev_week.beginning_of_week
    end_time = prev_week.end_of_week
    period = start_time..end_time

    # Only reports on Monday
    if Time.now.in_time_zone('Tokyo').wday == 1
      # Send report of previous week
      # uniq_visits = Ahoy::Visit.where(started_at: period).where.not(owner_id: nil).select(:owner_id).distinct(:owner_id)
      # uniq_visits.each do |visit|
      #   VisitAnalyticReportJob.perform_later(visit.owner_id)
      # end

      user_ids = Subscription.charge_required.pluck(:user_id)
      SlackClient.send(channel: 'sayhi', text: "Charging #{user_ids.size} user_id: #{user_ids.join(", ")}")
    end
  end

  task :service_usage => :environment do
    # Only reports on Monday
    if Time.now.in_time_zone('Tokyo').wday == 1
      today = Date.today

      metric = (0..11).to_a.map do |month|
        date = today.advance(months: -month)

        {
          "before #{date.to_s}" => OnlineService.where("created_at < ?", date).pluck(:user_id).uniq.count
        }
      end

      SlackClient.send(channel: 'sayhi', text: "User count ever had service, \n #{metric.join("\r\n")}")
    end
  end
end
