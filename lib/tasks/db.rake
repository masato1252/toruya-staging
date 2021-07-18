# frozen_string_literal: true

require "seeders/plan"

namespace :db do
  desc "Backs up heroku database and restores it locally."
  task import_from_heroku: [ :environment, :drop, :create ] do
    c = Rails.configuration.database_configuration[Rails.env]
    heroku_app_flag = " --app #{ENV["HEROKU_APP_NAME"]}"
    dump_file_name = "tmp/#{ENV["HEROKU_APP_NAME"]}_latest.dump"

    Bundler.with_clean_env do
      puts "[1/6] Removing local backup"
      `rm #{dump_file_name}`
      puts "[2/6] Capturing backup on Heroku"
      `heroku pg:backups capture DATABASE_URL#{heroku_app_flag}`
      puts "[3/6] Downloading backup onto disk"
      `curl -o #{dump_file_name} \`heroku pg:backups public-url #{heroku_app_flag} | cat\``
      puts "[4/6] Mounting backup on local database"
      `pg_restore --clean --verbose --no-acl --no-owner -h localhost -d #{c["database"]} #{dump_file_name}`
      puts "[5/6] Migrating local migrations"
      Rake::Task["db:migrate"].invoke
      puts "[6/6] Update all users password"
      User.all.find_each do |user|
        user.password = "password123"
        user.password_confirmation = "password123"
        user.save(validate: false)
      end
      puts "Done."
    end
  end

  task import_from_last_dump: [ :environment, :drop, :create ] do
    c = Rails.configuration.database_configuration[Rails.env]
    heroku_app_flag = " --app #{ENV["HEROKU_APP_NAME"]}"
    dump_file_name = "tmp/#{ENV["HEROKU_APP_NAME"]}_latest.dump"

    puts "[1/3] Mounting backup on local database"
    `pg_restore --clean --verbose --no-acl --no-owner -h localhost -d #{c["database"]} #{dump_file_name}`
    puts "[2/3] Migrating local migrations"
    Rake::Task["db:migrate"].invoke
    puts "[3/3] Update all users password"
    User.all.find_each do |user|
      user.password = "password123"
      user.password_confirmation = "password123"
      user.save!
    end
    puts "Done."
  end
end
