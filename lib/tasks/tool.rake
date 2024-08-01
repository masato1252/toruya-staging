# frozen_string_literal: true

require 'platform-api'
require "slack_client"

namespace :tools do
  task :stop_staging_scheduler do
    Bundler.with_clean_env do
      output = `heroku ps --app toruya-staging`
      scheduler = output[/(scheduler.\d+)/, 1]

      if scheduler.present?
        `heroku ps:stop #{scheduler} --app toruya-staging`
      end
    end
  end

  task :restart_dyno => :environment do
    puts "task restart_worker is on"
    heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])
    heroku.dyno.restart("toruya-production", "web.1")

    SlackClient.send(channel: 'development', text: "[OK] restart dyno") if Rails.configuration.x.env.production?
  end

  task :clean_track_data => :environment do
    Ahoy::Visit.find_in_batches do |visits|
      visit_ids = visits.map(&:id)
      Ahoy::Event.where(visit_id: visit_ids).delete_all
      Ahoy::Visit.where(id: visit_ids).delete_all
    end
  end

  task :cache_booking_pages => :environment do
    user_ids = Subscription.charge_required.pluck(:user_id)

    User.where(id: user_ids).find_each do |user|
      user.booking_pages.each do |booking_page|
        ::BookingPageCacheJob.perform_later(booking_page)
      end
    end
  end
end
