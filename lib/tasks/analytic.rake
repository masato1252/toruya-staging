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
      SlackClient.send(channel: 'reports', text: "Charging #{user_ids.size} user_id: #{user_ids.join(", ")}")
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

      SlackClient.send(channel: 'reports', text: "User count ever had service, \n #{metric.join("\r\n")}")
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

      google_worksheet = Google::Drive.spreadsheet(gid: 0)
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

      SlackClient.send(channel: 'reports', text: "Line settings number: \n#{metric.join("\r\n")}\n\nhttps://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=0")
    end
  end

  task :function_usage => :environment do
    # Only reports on 1st and 14th of each moth
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(gid: 846072525)
      new_row_number = google_worksheet.num_rows + 1

      new_row_data = [
        Time.current.to_fs(:date),
        BookingPage.select(:user_id).distinct.count,
        nil,
        OnlineService.select(:user_id).distinct.count,
        nil,
        SalePage.select(:user_id).distinct.count,
        nil,
        Broadcast.select(:user_id).distinct.count,
        nil,
        CustomerPayment.completed.count,
        nil,
        CustomerPayment.completed.sum(:amount_cents),
        nil,
        Menu.active.count,
        nil,
        BookingOption.active.count,
        nil,
        BookingPage.active.count,
        nil,
        SalePage.active.count,
        nil,
        SalePage.active.where(selling_price_amount_cents: nil, product_type: "OnlineService").count,
        nil,
        CustomerTicket.count,
        nil,
        CustomSchedule.closed.where.not(user_id: nil).count,
        nil,
        CustomMessage.count,
        nil,
        AccessProvider.stripe_connect.count,
        nil,
        AccessProvider.square.count,
        nil,
        Broadcast.count,
        nil,
        OnlineService.bundler.count,
        nil,
        Episode.count,
        nil,
        Lesson.count,
        nil,
        Customer.count,
        nil,
        User.count,
        nil,
        Subscription.charge_required.count,
        nil
      ]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end

      google_worksheet.save

      SlackClient.send(channel: 'reports', text: "Function usage \n\nhttps://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=846072525")
    end
  end

  task :function_biweekly_usage => :environment do
    # Only reports on 1st and 14th of each moth
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(gid: 1491437126)
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

      SlackClient.send(channel: 'reports', text: "Biweekly usage https://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=1491437126")
    end
  end

  task :paid_user_data => :environment do
    # Only reports on 1st and 14th of each moth
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(gid: 476056491)
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

      SlackClient.send(channel: 'reports', text: "Paid user usage \n\nhttps://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=476056491")
    end
  end

  # doc: https://docs.google.com/spreadsheets/d/1D5EQ2peahWivcS-NlakXE_zXzDOFo-MbJ14LwnV5_h4/edit#gid=0
  # map: https://www.google.com/maps/d/u/0/edit?hl=zh-TW&hl=zh-TW&mid=1H6wNjpf_z6PYab0tNcV_zI-46oe_0SM&ll=33.18436717659077%2C132.2792760282602&z=6
  task :paid_user_map_data => :environment do
    if Time.now.in_time_zone('Tokyo').day == 1 || Time.now.in_time_zone('Tokyo').day == 14
      google_worksheet = Google::Drive.spreadsheet(google_sheet_id: "1D5EQ2peahWivcS-NlakXE_zXzDOFo-MbJ14LwnV5_h4", worksheet: 0)

      row_data = Subscription.charge_required.map do |s|
        profile = s.user.profile
        sale_page = s.user.sale_pages.where(map_public: true).first

        [
          profile.company_name,
          profile.company_address,
          s.user.social_account.add_friend_url,
          sale_page ? Rails.application.routes.url_helpers.sale_page_url(sale_page.slug) : nil
        ]
      end

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
      google_worksheet = Google::Drive.spreadsheet(gid: 1444275187)
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
    #     revenue_of_month => 123,
    #     after_months =>[
    #       [],
    #     ],
    #     rate => [ ]
    #     dollar_rate => [ ]
    #   }
    # }
    current_month = Time.new(2021, 7)
    end_month = Time.current.prev_month.end_of_month.end_of_day
    join_user_ids = []
    joined_month = {}
    helper = ApplicationController.helpers
    total_reservations_count = 0
    total_people_month = 0

    while current_month < end_month
      last_month = current_month.next_month > end_month

      charges = SubscriptionCharge.completed.where(created_at: current_month..current_month.end_of_month.end_of_day)
      reservations = Reservation.where(created_at: current_month..current_month.end_of_month.end_of_day)

      user_ids = charges.pluck(:user_id)
      new_user_ids = user_ids - join_user_ids

      join_user_ids.concat(new_user_ids)
      year_month = current_month.strftime("%Y-%m")

      joined_month[year_month] ||= {}
      joined_month[year_month]["new_user_ids"] = new_user_ids
      joined_month[year_month]["new_user_base_amount"] = charges.where(user_id: new_user_ids).sum(:amount_cents)
      joined_month[year_month]["revenue_of_month"] = charges.sum(:amount_cents)

      joined_month.each do |month_of_year, metric|
        still_pay_user_ids = (metric["new_user_ids"] & user_ids)
        left_user_ids = metric["new_user_ids"] - still_pay_user_ids

        joined_month[month_of_year]["after_months"] ||= []
        joined_month[month_of_year]["after_months"] << still_pay_user_ids
        joined_month[month_of_year]["amount"] ||= []
        existing_users_paid = charges.where(user_id: still_pay_user_ids).sum(:amount_cents)
        existing_users_reservations = reservations.where(user_id: still_pay_user_ids).count

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

    ["retention_rate", "net_retention_rate", "money"].each do |scenario|
      gid = case scenario
            when "retention_rate"
              591602408
            when "net_retention_rate"
              1435973454
            when "money"
              1020433754
            end

      google_worksheet = Google::Drive.spreadsheet(gid: gid)

      joined_month
      new_row_number = 5
      start_column = 2
      joined_month.each do |year_month, metric|
        case scenario
        when "retention_rate"
          google_worksheet[new_row_number, start_column - 1] = total_reservations_count / total_people_month.to_f
          google_worksheet[new_row_number, start_column] = year_month
          google_worksheet[new_row_number, start_column + 1] = metric["new_user_ids"].length
          google_worksheet[new_row_number, start_column + 2] = metric["new_user_ids"].join(", ")
        when "net_retention_rate"
          google_worksheet[new_row_number, start_column] = year_month
          google_worksheet[new_row_number, start_column + 1] = metric["new_user_ids"].length
          google_worksheet[new_row_number, start_column + 2] = metric["new_user_ids"].join(", ")
        when "money"
          google_worksheet[new_row_number, start_column - 1] = metric["revenue_of_month"]
          google_worksheet[new_row_number, start_column] = year_month
          google_worksheet[new_row_number, start_column + 1] = metric["new_user_ids"].length
          google_worksheet[new_row_number, start_column + 2] = metric["new_user_ids"].join(", ")
        end

        if metric["rate"]
          metric["rate"].each.with_index do |rate, index|
            case scenario
            when "retention_rate"
              google_worksheet[new_row_number, index + start_column + 3] = rate
            when "net_retention_rate"
              google_worksheet[new_row_number, index + start_column + 3] = metric["dollar_rate"][index]
            when "money"
              google_worksheet[new_row_number, index + start_column + 3] = metric["amount"][index]
            end
          end
        end

        new_row_number = new_row_number + 1
      end

      google_worksheet.save
    end
  end

  task :user_business_status => :environment do
    user_ids = Subscription.charge_required.pluck(:user_id)
    google_worksheet = Google::Drive.spreadsheet(gid: 961862816)

    churn_user_ids = [923, 1660, 1057]
    reservation_per_month = (user_ids + churn_user_ids).map do |user_id|
      first_paid_date = SubscriptionCharge.where(user_id: user_id).completed.order("id").first&.created_at&.to_date
      next unless first_paid_date
      month_period = 3.0
      first_account_date = (month_period).to_i.months.ago.to_date

      user = User.find(user_id)
      owner_customer_id = user.owner_social_customer&.customer_id
      customer_ids = user.customer_ids
      reservation_ids = Reservation.where(user_id: user_id).where(created_at: first_account_date..).pluck(:id)
      reservation_customer_scope = ReservationCustomer.where(reservation_id: reservation_ids).where.not(customer_id: owner_customer_id).where(state: [:accepted, :pending])
      reservation_count = reservation_customer_scope.count

      reservation_amount = reservation_customer_scope.where(booking_option_id: user.booking_option_ids).sum(:booking_amount_cents)
      manual_reservation_ids = reservation_customer_scope.where(booking_option_id: nil).pluck(:reservation_id)
      manual_reservation_count =  manual_reservation_ids.length
      manual_reservation_amount = Reservation.where(id: manual_reservation_ids).map do |reservation|
        booking_option_ids = BookingOptionMenu.where(menu_id: reservation.menu_ids).pluck(:booking_option_id)
        user.booking_options.where(id: booking_option_ids).sum(:amount_cents) * reservation.customer_ids.length
      end.sum

      service_amount = CustomerPayment.where(customer_id: customer_ids - Array.wrap(owner_customer_id), product_type: "OnlineServiceCustomerRelation").where(created_at: first_account_date..).sum(:amount_cents)
      period = (Date.today - first_account_date).to_f
      last_reservation_date = reservation_customer_scope.last&.created_at&.to_s(:date)
      total_customers_count = Customer.where(user_id: user_id).count
      total_customers_recent_count = Customer.where(user_id: user_id).where(created_at: first_account_date...).count
      total_line_customers_count = SocialCustomer.where(user_id: user.id).count
      line_customer_for_recent_period = SocialCustomer.where(user_id: user.id).where(created_at: first_account_date..).count
      total_sale_page_recent_visit = Ahoy::Visit.where(owner_id: user_id, product_type: "SalePage").where(started_at: first_account_date..).count
      total_booking_page_recent_visit = Ahoy::Visit.where(owner_id: user_id, product_type: "BookingPage").where(started_at: first_account_date..).count
      social_messages_count = SocialMessage.where(social_account_id: user.social_account_id).where(created_at: first_account_date..).count
      customer_social_messages_count = SocialMessage.from_customer.where(social_account_id: user.social_account_id).where(created_at: first_account_date..).count
      completed_customer_payments_count = CustomerPayment.where(customer_id: customer_ids).completed.where(created_at: first_account_date..).count
      custom_schedules_count = CustomSchedule.where(user_id: user_id).where(created_at: first_account_date..).count

      {
        user_id: user_id,
        first_paid_date: first_paid_date&.to_s(:date),
        reservation_count_monthly: (reservation_count / month_period),
        reservation_revenue_monthly: (reservation_amount / month_period),
        manual_reservation_count_monthly: (manual_reservation_count / month_period),
        manual_reservation_revenue_monthly: (manual_reservation_amount / month_period),
        service_revenue_monthly: (service_amount / month_period),
        total_revenue_monthly: (reservation_amount + manual_reservation_amount + service_amount) / month_period,
        last_reservation_date: last_reservation_date,
        had_reservation_in_one_month: last_reservation_date ? last_reservation_date > 30.days.ago : false,
        had_reservation_in_three_week: last_reservation_date ? last_reservation_date > 21.days.ago : false,
        had_reservation_in_two_week: last_reservation_date ? last_reservation_date > 14.days.ago : false,
        had_reservation_in_one_week: last_reservation_date ? last_reservation_date > 7.days.ago : false,
        total_customers_count: total_customers_count,
        new_customer_monthly: (total_customers_recent_count / month_period),
        total_line_customers_count: total_line_customers_count,
        new_line_customer_monthly: (line_customer_for_recent_period / month_period),
        sale_page_visit_monthly: (total_sale_page_recent_visit / month_period),
        booking_page_visit_monthly: (total_booking_page_recent_visit / month_period),
        social_messages_count_monthly: (social_messages_count / month_period),
        customer_social_messages_count_monthly: (customer_social_messages_count / month_period),
        customer_payments_count_monthly: (completed_customer_payments_count / month_period),
        custom_schedules_count: (custom_schedules_count / month_period),
      }
    end.compact.sort_by {|r| r[:reservation_count_monthly] }

    new_row_number = 3
    reservation_per_month.each do |r|
      [
        %|=HYPERLINK("https://manager.toruya.com/admin/chats?user_id=#{r[:user_id]}", #{r[:user_id]})|,
        r[:reservation_count_monthly],
        r[:customer_payments_count_monthly],
        r[:custom_schedules_count],
        r[:customer_social_messages_count_monthly],
        r[:reservation_revenue_monthly],
        r[:manual_reservation_count_monthly],
        r[:manual_reservation_revenue_monthly],
        r[:service_revenue_monthly],
        r[:total_revenue_monthly],
        r[:total_customers_count],
        r[:new_customer_monthly],
        r[:total_line_customers_count],
        r[:new_line_customer_monthly],
        r[:sale_page_visit_monthly],
        r[:booking_page_visit_monthly],
        r[:social_messages_count_monthly],
        r[:had_reservation_in_one_month],
        r[:had_reservation_in_three_week],
        r[:had_reservation_in_two_week],
        r[:had_reservation_in_one_week],
        r[:first_paid_date],
        r[:last_reservation_date]
      ].each_with_index do |value, column_index|
        google_worksheet[new_row_number, column_index + 1] = value
      end

      new_row_number = new_row_number + 1
    end

    google_worksheet.save
  end

  task :free_user_status => :environment do
    current = Time.now.in_time_zone('Tokyo')

    # Only reports on Monday
    if current.wday == 1
      recent_1_week_users = Subscription.free.where(created_at: current.advance(weeks: -1)..current).includes(:user).map(&:user)
      recent_2_week_users = Subscription.free.where(created_at: current.advance(weeks: -2)..current.advance(weeks: -1)).includes(:user).map(&:user)
      recent_3_week_users = Subscription.free.where(created_at: current.advance(weeks: -3)..current.advance(weeks: -2)).includes(:user).map(&:user)
      recent_4_week_users = Subscription.free.where(created_at: current.advance(weeks: -4)..current.advance(weeks: -3)).includes(:user).map(&:user)

      message = [recent_1_week_users, recent_2_week_users, recent_3_week_users, recent_4_week_users].map.with_index(1) do |users, week_index|
        users_finished_settings_message = users.filter_map do |user|
          if user.social_account&.line_settings_verified?
            "<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|#{user.id}>"
          end
        end.join(", ")

        users_start_but_not_finished_settings_message = users.filter_map do |user|
          if user.social_account&.is_login_available? && !user.social_account&.line_settings_verified?
            "<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|#{user.id}>"
          end
        end.join(", ")

        users_not_start_settings_message = users.filter_map do |user|
          if !user.social_account&.is_login_available?
            "<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|#{user.id}>"
          end
        end.join(", ")

        "Last #{week_index} week Free users\nFinished Settings: #{users_finished_settings_message} \nStart But not Finished: #{users_start_but_not_finished_settings_message}\nNOT START: #{users_not_start_settings_message}"
      end.join("\n\n")

      message = "Unpaid users\n\n#{message}\n\nhttps://docs.google.com/spreadsheets/d/1okgAXtvc_3pm8fyNUZS0UKO2KkE7NTGw5vPBdTbzlLg/edit#gid=1913363436"

      SlackClient.send(channel: 'reports', text: message)
    end
  end

  task :retention_months => :environment do
    current = Time.now.in_time_zone('Tokyo')

    # Only reports on Monday
    if current.wday == 1
      google_worksheet = Google::Drive.spreadsheet(gid: 1945229869)
      paid_user_ids = SubscriptionCharge.distinct(:user_id).pluck(:user_id)

      new_row_number = 2
      paid_user_ids.each do |user_id|
        [
          user_id,
          SubscriptionCharge.where(user_id: user_id).completed.count,
          SubscriptionCharge.where(user_id: user_id).completed.where("created_at > ?", 1.month.ago).count
        ].each_with_index do |value, column_index|
          google_worksheet[new_row_number, column_index + 1] = value
        end

        new_row_number = new_row_number + 1
      end

      google_worksheet.save
    end
  end

  task :key_metrics => :environment do
    current = Time.now.in_time_zone('Tokyo')

    # Only reports on Monday
    if current.wday == 1
      google_worksheet = Google::Drive.spreadsheet(gid: 203455717)

      date_period = current.advance(weeks: -1)..current
      date_period_formatted = "#{date_period.begin.to_date} to #{date_period.end.to_date}"
      user_sign_up_in_previous_week = User.where(created_at: date_period).count
      user_sign_up_in_previous_week_ids = User.where(created_at: date_period).pluck(:id)
      user_has_booking_page_ids = BookingPage.where(user_id: user_sign_up_in_previous_week_ids).pluck(:user_id)
      reservation_count = Reservation.where(user_id: user_sign_up_in_previous_week_ids).count
      paid_user_ids = Subscription.where(user_id: user_sign_up_in_previous_week_ids).charge_required.pluck(:user_id)

      # Date,
      new_row_number = google_worksheet.num_rows + 1
      new_row_data = [
        date_period_formatted,
        user_sign_up_in_previous_week,
        user_has_booking_page_ids.uniq.count,
        reservation_count,
        paid_user_ids.count,
        user_has_booking_page_ids.uniq.join(", "),
        paid_user_ids.uniq.join(", ")
      ]
      new_row_data.each_with_index do |data, index|
        google_worksheet[new_row_number, index + 1] = data
      end

      google_worksheet.save
    end
  end
end
