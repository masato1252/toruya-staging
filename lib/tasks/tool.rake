# frozen_string_literal: true

require 'platform-api'
require "slack_client"
require 'csv'

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
    # Every 2 hours
    if Time.current.hour % 2 == 0
      user_ids = Subscription.charge_required.pluck(:user_id)

      User.where(id: user_ids).find_each do |user|
        user.booking_pages.started.end_yet.each do |booking_page|
          ::BookingPageCacheJob.perform_later(booking_page)
        end
      end
    end
  end

  task :update_holidays => :environment do
    # https://data.gov.tw/dataset/14718
    csv_file_url = "https://www.dgpa.gov.tw/FileConversion?filename=dgpa/files/202407/22f9fcbc-fbb2-4387-8bcf-73b2279666c2.csv&nfix=&name=114%E5%B9%B4%E4%B8%AD%E8%8F%AF%E6%B0%91%E5%9C%8B%E6%94%BF%E5%BA%9C%E8%A1%8C%E6%94%BF%E6%A9%9F%E9%97%9C%E8%BE%A6%E5%85%AC%E6%97%A5%E6%9B%86%E8%A1%A8.csv"

    # download the csv from csv_file_url and save to config/holidays/tw_holidays.csv
    csv_file_path = Rails.root.join('config', 'holidays', 'tw_holidays.csv')
    File.open(csv_file_path, 'wb') do |file|
      file.write(HTTParty.get(csv_file_url).body)
    end

    # header: 西元日期,星期,是否放假,備註
    yml_data = {}

    CSV.foreach(csv_file_path, headers: true) do |row|
      date = Date.parse(row[0])
      is_holiday = row[2] == '2'

      if is_holiday && !date.saturday? && !date.sunday?
        year = date.year.to_s
        yml_data[year] ||= {}
        yml_data[year][date.month] ||= []
        yml_data[year][date.month] << date.strftime('%Y/%m/%d')

        yml_file_path = Rails.root.join('config', 'holidays', "tw.yml")
        
        if File.exist?(yml_file_path)
          existing_data = YAML.load_file(yml_file_path)
          merged_data = existing_data.present? ? existing_data.deep_merge(yml_data) : yml_data
          File.write(yml_file_path, merged_data.to_yaml)
        else
          File.write(yml_file_path, yml_data.to_yaml)
        end
      end
    end

    puts "Holidays updated successfully"
  end
end
