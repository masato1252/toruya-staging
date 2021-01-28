require 'platform-api'

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

    Slack::Web::Client.new.chat_postMessage(channel: 'development', text: "[OK] restart dyno") if Rails.configuration.x.env.production?
  end
end
