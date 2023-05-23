# frozen_string_literal: true

require "slack_client"
require "google/drive"

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

  task :line_settings => :environment do
    # Only reports on Monday
    if Time.now.in_time_zone('Tokyo').wday == 1
      accounts = SocialAccount.where.not(channel_id: nil, channel_token: nil, channel_secret: nil, basic_id: nil, label: nil, login_channel_id: nil, login_channel_secret: nil)
      total_line_user_count = SocialUser.count.to_f
      total_toruya_user_count = User.count.to_f
      total_line_settings = SocialAccount.count.to_f

      line_settings_done_count = accounts.all.find_all {|s| s.line_settings_finished? }.size
      login_api_verified_count = accounts.all.find_all {|s| s.login_api_verified? }.size
      message_api_verified_count = accounts.find_all {|s| s.message_api_verified? }.size

      helper = ApplicationController.helpers

      # Line setting done percentage
      setting_done_line_user_percent = helper.number_to_percentage(line_settings_done_count * 100 / total_line_user_count, precision: 1)
      setting_done_toruya_user_percent = helper.number_to_percentage(line_settings_done_count * 100 / total_toruya_user_count, precision: 1)
      setting_done_total_settings_percent = helper.number_to_percentage(line_settings_done_count * 100 / total_line_settings, precision: 1)

      # line login api verified percentage
      login_verified_line_user_percent = helper.number_to_percentage(login_api_verified_count * 100 / total_line_user_count, precision: 1)
      login_verified_toruya_user_percent = helper.number_to_percentage(login_api_verified_count * 100 / total_toruya_user_count, precision: 1)
      login_verified_total_settings_percent = helper.number_to_percentage(login_api_verified_count * 100 / total_line_settings, precision: 1)

      # message api verifid percentage
      message_verified_line_user_percent = helper.number_to_percentage(message_api_verified_count * 100 / total_line_user_count, precision: 1)
      message_verified_toruya_user_percent = helper.number_to_percentage(message_api_verified_count * 100 / total_toruya_user_count, precision: 1)
      message_verified_total_settings_percent = helper.number_to_percentage(message_api_verified_count * 100 / total_line_settings, precision: 1)

      metric = [
        { "Line User count" => total_line_user_count.to_i },
        { "Toruya User count" => "#{total_toruya_user_count.to_i} ( #{helper.number_to_percentage(total_toruya_user_count * 100 / total_line_user_count, precision: 1)} )" },
        { "Toruya User try to set up line count" => "#{total_line_settings.to_i} ( #{helper.number_to_percentage(total_line_settings * 100 / total_line_user_count, precision: 1)} / #{helper.number_to_percentage(total_line_settings * 100 / total_toruya_user_count, precision: 1)} )" },
        { "line_settings_done_count" => "#{line_settings_done_count} ( #{setting_done_line_user_percent} / #{setting_done_toruya_user_percent} / #{setting_done_total_settings_percent} )" },
        { :login_api_verified_count => "#{login_api_verified_count} ( #{login_verified_line_user_percent} / #{login_verified_toruya_user_percent} / #{login_verified_total_settings_percent} )" },
        { message_api_verified_count: "#{message_api_verified_count} ( #{message_verified_line_user_percent} / #{message_verified_toruya_user_percent} / #{message_verified_total_settings_percent} )" }
      ]

      SlackClient.send(channel: 'sayhi', text: "Line settings number: \n#{metric.join("\r\n")}")

      google_worksheet = Google::Drive.spreadsheet(worksheet: 0)
      new_row_number = google_worksheet.num_rows + 1
      new_row_data = [Date.today.to_fs, total_line_settings.to_i, line_settings_done_count, login_api_verified_count, message_api_verified_count]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end
      google_worksheet.save
  end
end
