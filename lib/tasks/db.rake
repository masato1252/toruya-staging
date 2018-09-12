namespace :db do

  desc "Backs up heroku database and restores it locally."
  task import_from_heroku: [ :environment, :create ] do
    c = Rails.configuration.database_configuration[Rails.env]
    heroku_app_flag = " --app #{ENV["HEROKU_APP_NAME"]}"

    Bundler.with_clean_env do
      puts "[1/5] Capturing backup on Heroku"
      `heroku pg:backups capture DATABASE_URL#{heroku_app_flag}`
      puts "[2/5] Downloading backup onto disk"
      `curl -o tmp/latest.dump \`heroku pg:backups public-url #{heroku_app_flag} | cat\``
      puts "[3/5] Mounting backup on local database"
      `pg_restore --clean --verbose --no-acl --no-owner -h localhost -d #{c["database"]} tmp/latest.dump`
      puts "[4/5] Removing local backup"
      `rm tmp/latest.dump`
      puts "[5/5] Migrating local migrations"
      Rake::Task["db:migrate"].invoke
      puts "Done."
    end
  end
end
