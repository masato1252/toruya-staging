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

      user_ids = Subscription.charge_required.unexpired.pluck(:user_id)
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
    # Only reports on 1st and 14th of each moth
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
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
        { "Toruya User try to set up line count" => "#{total_line_settings.to_i} ( #{helper.number_to_percentage(total_line_settings * 100 / total_line_user_count, precision: 1)} / #{} )" },
        { "line_settings_done_count" => "#{line_settings_done_count} ( #{setting_done_line_user_percent} / #{setting_done_toruya_user_percent} / #{setting_done_total_settings_percent} )" },
        { :login_api_verified_count => "#{login_api_verified_count} ( #{login_verified_line_user_percent} / #{login_verified_toruya_user_percent} / #{login_verified_total_settings_percent} )" },
        { message_api_verified_count: "#{message_api_verified_count} ( #{message_verified_line_user_percent} / #{message_verified_toruya_user_percent} / #{message_verified_total_settings_percent} )" }
      ]

      google_worksheet = Google::Drive.spreadsheet(worksheet: 0)
      new_row_number = google_worksheet.num_rows + 1
      new_row_data = [
        Time.current.to_fs(:date),
        total_toruya_user_count.to_i,
        nil,
        total_line_settings.to_i,
        line_settings_done_count,
        login_api_verified_count,
        message_api_verified_count
      ]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end
      google_worksheet.save

      SlackClient.send(channel: 'sayhi', text: "Line settings number: \n#{metric.join("\r\n")}\n\nhttps://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=0")
    end
  end

  task :function_usage => :environment do
    # Only reports on 1st and 14th of each moth
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(worksheet: 1)
      new_row_number = google_worksheet.num_rows + 1

      new_row_data = [
        Time.current.to_fs(:date),
        BookingPage.select(:user_id).distinct.count,
        OnlineService.select(:user_id).distinct.count,
        SalePage.select(:user_id).distinct.count,
        Broadcast.select(:user_id).distinct.count,
        CustomerPayment.completed.count,
        CustomerPayment.completed.sum(:amount_cents)
      ]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end

      google_worksheet.save

      SlackClient.send(channel: 'sayhi', text: "Function usage \n\nhttps://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=846072525")
    end
  end

  task :function_biweekly_usage => :environment do
    # Only reports on 1st and 14th of each moth
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(worksheet: 2)
      new_row_number = google_worksheet.num_rows + 1

      new_row_data = [
        Time.current.to_fs(:date),
        BookingPage.where(created_at: 14.days.ago..Time.current).select(:user_id).distinct.count,
        OnlineService.where(created_at: 14.days.ago..Time.current).select(:user_id).distinct.count,
        SalePage.where(created_at: 14.days.ago..Time.current).select(:user_id).distinct.count,
        Broadcast.where(created_at: 14.days.ago..Time.current).select(:user_id).distinct.count,
        CustomerPayment.completed.where(created_at: 14.days.ago..Time.current).count,
        CustomerPayment.completed.where(created_at: 14.days.ago..Time.current).sum(:amount_cents)
      ]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end

      google_worksheet.save

      SlackClient.send(channel: 'sayhi', text: "Biweekly usage https://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=1491437126")
    end
  end

  task :paid_user_data => :environment do
    # Only reports on 1st and 14th of each moth
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(worksheet: 3)
      new_row_number = google_worksheet.num_rows + 1

      last_month_paid_user_ids = SubscriptionCharge.where(created_at: 2.month.ago..1.month.ago).pluck(:user_id).uniq
      current_month_paid_user_ids = SubscriptionCharge.where(created_at: 1.month.ago..Time.current).pluck(:user_id).uniq
      new_row_data = [
        Time.current.to_fs(:date),
        Subscription.charge_required.unexpired.count,
        (current_month_paid_user_ids - last_month_paid_user_ids).length,
        (last_month_paid_user_ids - current_month_paid_user_ids).length,
        (current_month_paid_user_ids - last_month_paid_user_ids).join(", "),
        (last_month_paid_user_ids - current_month_paid_user_ids).join(", ")
      ]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end

      google_worksheet.save

      SlackClient.send(channel: 'sayhi', text: "Paid user usage \n\nhttps://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=476056491")
    end
  end

  task :paid_user_map_data => :environment do
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(google_sheet_id: "1D5EQ2peahWivcS-NlakXE_zXzDOFo-MbJ14LwnV5_h4", worksheet: 0)

      row_data = Subscription.charge_required.map{|s| ppp = s.user.profile; [ppp.company_name, ppp.company_address, ppp.phone_number] }
      row_data.each_with_index do |col_data, row_number|
        col_data.each_with_index do |data, col_index|
          google_worksheet[row_number + 2, col_index + 1] = data
        end
      end

      google_worksheet.save
    end
  end

  task :reply_time => :environment do
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(worksheet: 5)
      new_row_number = google_worksheet.num_rows + 1
      no_reply_user_ids = []

      reply_periods = SocialUserMessage.where(message_type: 2, created_at: 14.days.ago..).group_by(&:social_user_id).map do |social_user_id, messages|
        last_user_message = messages.last
        last_staff_message = SocialUserMessage.where(message_type: 1, social_user_id: social_user_id).where("created_at < ?", last_user_message.created_at).last
        last_staff_message_time = last_staff_message&.created_at || 14.days.ago
        first_user_message = messages.sort_by(&:created_at).find { |m| m.created_at > last_staff_message_time }

        staff_reply = SocialUserMessage.where(message_type: 1).where("created_at > ?", first_user_message.created_at).first if first_user_message

        if staff_reply
          period = staff_reply.created_at - first_user_message.created_at

          { SocialUser.find(social_user_id).user_id => period / 3600.0 }
        else
          no_reply_user_ids << SocialUser.find(social_user_id).user_id 
          { SocialUser.find(social_user_id).user_id => nil || 48 }
        end
      end

      period_hours = reply_periods.map {|k| k.values.first }.compact
      average_reply_time = period_hours.sum/period_hours.length

      average_messages_count_a_day = SocialUserMessage.where(message_type: 2, created_at: 14.days.ago..).count / (14.0)

      new_row_data = [
        "#{14.days.ago.to_fs(:date)} ~ #{Time.current.to_fs(:date)}",
        average_reply_time,
        average_messages_count_a_day,
        no_reply_user_ids.join(", ")
      ]

      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end

      google_worksheet.save
    end
  end

  task :retention_rate => :environment do
    # join_user_ids = []
    # joined_month = {
    #   "year-month" => {
    #     new_user_ids => [],
    #     new_user_base_amount => 0,
    #     after_months =>[
    #       [],
    #     ],
    #     rate => [ ]
    #     dollar_rate => [ ]
    #   }
    # }
    current_month = Time.new(2021, 7)
    end_month = Time.current.prev_month.end_of_month
    join_user_ids = []
    joined_month = {}
    helper = ApplicationController.helpers

    scenario = ENV['scenario'] || "retention_rate" # net_retention_rate, amount

    while current_month < end_month
      charges = SubscriptionCharge.completed.where(created_at: current_month..current_month.end_of_month)
      user_ids = charges.pluck(:user_id)
      new_user_ids = user_ids - join_user_ids

      join_user_ids.concat(new_user_ids)
      year_month = current_month.strftime("%Y-%m")

      joined_month[year_month] ||= {}
      joined_month[year_month]["new_user_ids"] = new_user_ids
      joined_month[year_month]["new_user_base_amount"] = charges.where(user_id: new_user_ids).sum(:amount_cents)

      joined_month.each do |month_of_year, metric|
        still_pay_user_ids = (metric["new_user_ids"] & user_ids)

        joined_month[month_of_year]["after_months"] ||= []
        joined_month[month_of_year]["after_months"] << still_pay_user_ids
        joined_month[month_of_year]["amount"] ||= []
        existing_users_paid = charges.where(user_id: still_pay_user_ids).sum(:amount_cents)
        joined_month[month_of_year]["amount"] << existing_users_paid

        joined_month[month_of_year]["rate"] ||= []
        joined_month[month_of_year]["dollar_rate"] ||= []

        if metric["new_user_ids"].blank?
          joined_month[month_of_year]["rate"] << ""
          joined_month[month_of_year]["dollar_rate"] << ""
        elsif still_pay_user_ids.blank?
          joined_month[month_of_year]["rate"] << 0
          joined_month[month_of_year]["dollar_rate"] << ""
        else
          joined_month[month_of_year]["rate"] << (still_pay_user_ids.length / metric["new_user_ids"].length.to_f).round(2)
          joined_month[month_of_year]["dollar_rate"] << existing_users_paid / metric["new_user_base_amount"].to_f
        end
      end

      current_month = current_month.next_month
    end

    worksheet = case scenario
                when "retention_rate"
                  6
                when "net_retention_rate"
                  7
                when "amount"
                  8
                end

    google_worksheet = Google::Drive.spreadsheet(worksheet: worksheet)

    joined_month
    new_row_number = 5
    start_column = 2
    joined_month.each do |year_month, metric|
      google_worksheet[new_row_number, start_column] = year_month
      google_worksheet[new_row_number, start_column + 1] = metric["new_user_ids"].length
      google_worksheet[new_row_number, start_column + 2] = metric["new_user_ids"].join(", ")

      if metric["rate"]
        metric["rate"].each.with_index do |rate, index|
          case scenario
          when "retention_rate"
            google_worksheet[new_row_number, index + start_column + 3] = rate
          when "net_retention_rate"
            google_worksheet[new_row_number, index + start_column + 3] = metric["dollar_rate"][index]
          when "amount"
            google_worksheet[new_row_number, index + start_column + 3] = metric["amount"][index]
          end
        end
      else
      end

      new_row_number = new_row_number + 1
    end

    google_worksheet.save
  end
end
