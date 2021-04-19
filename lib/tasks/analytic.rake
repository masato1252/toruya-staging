# frozen_string_literal: true

namespace :analytic do
  task :landing_page_visit => :environment do
    prev_week = Time.now.prev_week
    start_time = prev_week.beginning_of_week
    end_time = prev_week.end_of_week
    period = start_time..end_time

    # Only reports on Monday
    if Time.now.wday == 1
      # Send report of previous week
      Ahoy::Visit.where(started_at: period).where.not(owner_id: nil).select(:owner_id).distinct(:owner_id).find_each do |visit|
        VisitAnalyticReportJob.perform_later(visit.owner_id)
      end
    end
  end
end
