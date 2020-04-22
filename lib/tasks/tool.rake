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
end
