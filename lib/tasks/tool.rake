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

  desc "Export user_id and booking option names (comma-separated) to CSV. OUTPUT=path optional."
  task export_user_booking_option_names: :environment do
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "user_booking_option_names.csv").to_s)

    rows = BookingOption.undeleted.order(:user_id, :id).group_by(&:user_id).map do |user_id, options|
      [user_id, options.map(&:name).join(",")]
    end

    CSV.open(output_path, "w", write_headers: true, headers: %w[user_id booking_option_names]) do |csv|
      rows.each { |row| csv << row }
    end

    puts "Wrote #{rows.size} rows to #{output_path}"
  end

  desc <<~DESC
    Export completed segment broadcast history (one row per broadcast) to CSV.
    Columns: user_id, broadcast_id, 一括配信日時, 配信種別, 配信条件, 配信数
    OUTPUT=path optional. LOCALE=ja (default)
  DESC
  task export_segment_broadcast_history: :environment do
    require Rails.root.join("app/helpers/settings_helper")

    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "segment_broadcast_history.csv").to_s)
    I18n.locale = ENV.fetch("LOCALE", "ja").to_sym

    helper = Object.new.extend(SettingsHelper)
    scope = Broadcast.final
      .where.not(sent_at: nil)
      .where(query_type: Broadcast::NORMAL_TYPES)
      .includes(:user)
      .order(:user_id, sent_at: :desc, id: :desc)

    headers = %w[
      user_id
      broadcast_id
      一括配信日時
      配信種別
      配信条件
      配信数
    ]

    row_count = 0
    CSV.open(output_path, "w", write_headers: true, headers: headers, force_quotes: true) do |csv|
      scope.find_each do |broadcast|
        query_type_label =
          I18n.t(
            "user_bot.dashboards.broadcast_creation.#{broadcast.query_type}",
            default: broadcast.query_type
          )
        targets = broadcast.targets.join(", ")
        delivery_conditions = targets.present? ? "#{query_type_label} / #{targets}" : query_type_label

        csv << [
          broadcast.user_id,
          broadcast.id,
          helper.broadcast_deliver_at(broadcast),
          query_type_label,
          targets,
          broadcast.recipients_count
        ]
        row_count += 1
      end
    end

    user_count = scope.distinct.count(:user_id)
    puts "Wrote #{row_count} broadcasts for #{user_count} users to #{output_path}"
  end

  desc <<~DESC
    Export per user_id counts of custom reservation reminder settings (shop + booking page).
    Columns: user_id, 予約前リマインドカスタム設定数, 予約後リマインドカスタム設定数
    OUTPUT=path optional.
  DESC
  task export_reservation_custom_reminder_counts: :environment do
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "reservation_custom_reminder_counts.csv").to_s)
    shop_scenario = CustomMessages::Customers::Template::SHOP_CUSTOM_REMINDER
    booking_page_scenario = CustomMessages::Customers::Template::BOOKING_PAGE_CUSTOM_REMINDER

    count_for = lambda do |before:|
      shop_counts =
        CustomMessage
          .where(scenario: shop_scenario, service_type: "Shop")
          .then { |s| before ? s.where.not(before_minutes: nil) : s.where.not(after_days: nil) }
          .joins("INNER JOIN shops ON shops.id = custom_messages.service_id AND shops.deleted_at IS NULL")
          .group("shops.user_id")
          .count

      booking_page_counts =
        CustomMessage
          .where(scenario: booking_page_scenario, service_type: "BookingPage")
          .then { |s| before ? s.where.not(before_minutes: nil) : s.where.not(after_days: nil) }
          .joins("INNER JOIN booking_pages ON booking_pages.id = custom_messages.service_id AND booking_pages.deleted_at IS NULL")
          .group("booking_pages.user_id")
          .count

      shop_counts.merge(booking_page_counts) { |_uid, a, b| a + b }
    end

    before_counts = count_for.call(before: true)
    after_counts = count_for.call(before: false)
    user_ids = (
      Shop.active.distinct.pluck(:user_id) +
      BookingPage.active.distinct.pluck(:user_id) +
      before_counts.keys +
      after_counts.keys
    ).uniq.sort

    headers = %w[user_id 予約前リマインドカスタム設定数 予約後リマインドカスタム設定数]
    CSV.open(output_path, "w", write_headers: true, headers: headers, force_quotes: true) do |csv|
      user_ids.each do |user_id|
        csv << [user_id, before_counts[user_id] || 0, after_counts[user_id] || 0]
      end
    end

    puts "Wrote #{user_ids.size} users to #{output_path}"
    puts "  予約前 settings total: #{before_counts.values.sum}"
    puts "  予約後 settings total: #{after_counts.values.sum}"
  end

  desc <<~DESC
    Export step-delivery timing labels per user_id and online_service_id (one row per service).
    Columns: user_id, online_service_id, ステップ配信頻度
    OUTPUT=path optional. LOCALE=ja (default)
  DESC
  task export_user_online_service_step_delivery_words: :environment do
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "user_online_service_step_delivery_words.csv").to_s)
    I18n.locale = ENV.fetch("LOCALE", "ja").to_sym
    scenario = CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED

    timing_word = lambda do |message|
      if message.after_days.present?
        I18n.t(
          "user_bot.dashboards.settings.custom_message.online_service.after_days",
          after_days: message.after_days
        )
      else
        I18n.t("user_bot.dashboards.settings.custom_message.online_service.online_service_purchased")
      end
    end

    headers = %w[user_id online_service_id ステップ配信頻度]
    row_count = 0
    services_with_steps = 0

    CSV.open(output_path, "w", write_headers: true, headers: headers, force_quotes: true) do |csv|
      OnlineService.not_deleted.order(:user_id, :id).find_each do |online_service|
        scope = CustomMessage.scenario_of(online_service, scenario)
        service_words = []
        purchased = scope.right_away.first
        service_words << timing_word.call(purchased) if purchased
        scope.sequence.order("after_days ASC").each { |message| service_words << timing_word.call(message) }

        csv << [online_service.user_id, online_service.id, service_words.join(",")]
        row_count += 1
        services_with_steps += 1 if service_words.any?
      end
    end

    puts "Wrote #{row_count} rows (#{services_with_steps} with step settings) to #{output_path}"
  end

  desc <<~DESC
    Export per user_id rich menu mode (手動/自動) and Toruya menu names when auto.
    Columns: user_id, リッチメニュータイプ, 設定名称
    OUTPUT=path optional.
  DESC
  task export_user_rich_menu_settings: :environment do
    script = Rails.root.join("tmp/export_user_rich_menu_settings.rb")
    raise "Missing #{script}" unless script.exist?

    load script
  end

  desc "Export user_id and booking_page_id for LINE keyword booking pages (line_sharing ON). OUTPUT=path optional."
  task export_line_keyword_booking_pages_list: :environment do
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "line_keyword_booking_pages_list.csv").to_s)
    row_count = 0

    CSV.open(output_path, "w", write_headers: true, headers: %w[user_id LINE送信ONの予約ページID タイトル 挨拶文], force_quotes: true) do |csv|
      User.joins(:user_setting).order(:id).find_each do |user|
        page_ids = user.line_keyword_booking_page_ids
        next if page_ids.empty?

        pages_by_id = BookingPage.unscoped.where(id: page_ids).index_by { |p| p.id.to_s }

        page_ids.each do |page_id|
          page = pages_by_id[page_id.to_s]
          csv << [user.id, page_id, page&.title, page&.greeting]
          row_count += 1
        end
      end
    end

    puts "Wrote #{row_count} rows to #{output_path}"
  end

  desc "Export per user_id count of LINE keyword booking pages. OUTPUT=path optional."
  task export_line_keyword_booking_page_counts: :environment do
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "line_keyword_booking_page_counts.csv").to_s)

    headers = %w[user_id LINE送信する予約ページ数]
    row_count = 0

    CSV.open(output_path, "w", write_headers: true, headers: headers, force_quotes: true) do |csv|
      User.joins(:user_setting).order(:id).find_each do |user|
        count = user.line_keyword_booking_page_ids.size
        csv << [user.id, count]
        row_count += 1
      end
    end

    users_with_pages = User.joins(:user_setting).where("cardinality(user_settings.line_keyword_booking_page_ids) > 0").count
    puts "Wrote #{row_count} rows to #{output_path}"
    puts "  users with count > 0: #{users_with_pages}"
  end

  desc "Export user_id and online service names (comma-separated) to CSV. OUTPUT=path optional."
  task export_user_online_service_names: :environment do
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "user_online_service_names.csv").to_s)

    rows = OnlineService.not_deleted.order(:user_id, :id).group_by(&:user_id).map do |user_id, services|
      [user_id, services.map(&:name).join(",")]
    end

    CSV.open(output_path, "w", write_headers: true, headers: %w[user_id online_service_names]) do |csv|
      rows.each { |row| csv << row }
    end

    puts "Wrote #{rows.size} rows to #{output_path}"
  end

  desc "Export per-user counts: shop/online booking options and online services. OUTPUT=path optional."
  task export_user_booking_and_service_counts: :environment do
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "user_booking_and_service_counts.csv").to_s)

    # 予約メニューの店舗/オンラインは、紐づくメニューの開催方法（menus.online）に準拠。
    # BookingOption#online? … いずれかのメニューが online ならオンライン予約メニュー、それ以外は店舗。
    online_menu_exists_sql = <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM booking_option_menus bom
        INNER JOIN menus m ON m.id = bom.menu_id
        WHERE bom.booking_option_id = booking_options.id
          AND m.online = TRUE
          AND m.deleted_at IS NULL
      )
    SQL

    online_booking_counts = BookingOption.undeleted
      .where(online_menu_exists_sql)
      .group(:user_id)
      .count

    shop_counts = BookingOption.undeleted
      .where.not(online_menu_exists_sql)
      .group(:user_id)
      .count

    online_service_counts = OnlineService.not_deleted.group(:user_id).count

    user_ids = (shop_counts.keys + online_booking_counts.keys + online_service_counts.keys).uniq.sort

    headers = %w[
      user_id
      shop_booking_option_count
      online_booking_option_count
      online_service_count
    ]

    CSV.open(output_path, "w", write_headers: true, headers: headers) do |csv|
      user_ids.each do |user_id|
        csv << [
          user_id,
          shop_counts[user_id] || 0,
          online_booking_counts[user_id] || 0,
          online_service_counts[user_id] || 0
        ]
      end
    end

    puts "Wrote #{user_ids.size} rows to #{output_path}"
  end

  desc <<~DESC
    Export LINE follower insight (GET /v2/bot/insight/followers) per user_id.
    ENV: FROM_DATE=20240101 TO_DATE=20260531 GRANULARITY=monthly|end|daily (default monthly)
         OUTPUT=path SLEEP_MS=200
  DESC
  task export_line_follower_insights: :environment do
    require Rails.root.join("lib/line_insight_client")

    from_date = Date.strptime(ENV.fetch("FROM_DATE", "20240101"), "%Y%m%d")
    to_date = Date.strptime(ENV.fetch("TO_DATE", "20260531"), "%Y%m%d")
    granularity = ENV.fetch("GRANULARITY", "monthly")
    sleep_sec = ENV.fetch("SLEEP_MS", "200").to_i / 1000.0
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "user_line_follower_insights.csv").to_s)

    dates =
      case granularity
      when "end"
        [to_date]
      when "daily"
        (from_date..to_date).to_a
      when "monthly"
        monthly_dates = []
        cursor = from_date.beginning_of_month
        while cursor <= to_date
          monthly_dates << [cursor.end_of_month, to_date].min
          cursor = cursor.next_month
        end
        monthly_dates.uniq
      else
        raise ArgumentError, "Unknown GRANULARITY=#{granularity} (use monthly, end, or daily)"
      end
    accounts = SocialAccount.all.select(&:bot_data_finished?).sort_by(&:user_id)

    headers = %w[
      user_id
      social_account_id
      date
      followers
      targeted_reaches
      blocks
      api_status
      error
    ]

    row_count = 0
    error_count = 0

    CSV.open(output_path, "w", write_headers: true, headers: headers) do |csv|
      accounts.each do |account|
        token = account.raw_channel_token
        unless token.present?
          dates.each do |date|
            csv << [account.user_id, account.id, date.strftime("%Y-%m-%d"), nil, nil, nil, nil, "missing_token"]
            row_count += 1
            error_count += 1
          end
          next
        end

        dates.each do |date|
          date_param = date.strftime("%Y%m%d")
          begin
            body = LineInsightClient.get_number_of_followers(channel_token: token, date: date_param)
            status = body["status"]
            if status == "ready"
              csv << [
                account.user_id,
                account.id,
                date.strftime("%Y-%m-%d"),
                body["followers"],
                body["targetedReaches"],
                body["blocks"],
                status,
                nil
              ]
            else
              csv << [
                account.user_id,
                account.id,
                date.strftime("%Y-%m-%d"),
                nil,
                nil,
                nil,
                status,
                nil
              ]
              error_count += 1
            end
          rescue LineInsightClient::Error, StandardError => e
            csv << [account.user_id, account.id, date.strftime("%Y-%m-%d"), nil, nil, nil, nil, e.message]
            error_count += 1
          end
          row_count += 1
          sleep(sleep_sec) if sleep_sec.positive?
        end
      end
    end

    puts "Wrote #{row_count} rows (#{accounts.size} accounts, #{dates.size} dates, granularity=#{granularity}) to #{output_path}"
    puts "Rows with empty metrics or errors: #{error_count}"
  end

  desc <<~DESC
    Add LINE demographic insight (gender/age/area ratios) to an existing follower-insight CSV.
    ENV: INPUT=path OUTPUT=path SLEEP_MS=200
    If the first month of an account fails with API error, skip all later months for that account.
  DESC
  task enrich_line_follower_insights_with_demographics: :environment do
    require Rails.root.join("lib/line_insight_client")

    input_path = ENV.fetch("INPUT", Rails.root.join("tmp", "user_line_follower_insights_production.csv").to_s)
    output_path = ENV.fetch("OUTPUT", Rails.root.join("tmp", "user_line_follower_insights_production_with_demographics.csv").to_s)
    sleep_sec = ENV.fetch("SLEEP_MS", "200").to_i / 1000.0

    rows = CSV.read(input_path, headers: true)
    rows_with_index = rows.each_with_index.map { |row, idx| [row, idx] }
    grouped_rows = rows_with_index.group_by { |(row, _idx)| row["social_account_id"].to_s }

    ratio_hash = lambda do |items, key_name|
      return {} unless items.is_a?(Array)

      items.each_with_object({}) do |item, result|
        next unless item.is_a?(Hash)

        raw_key = item[key_name] || item[key_name.to_sym]
        percentage = item["percentage"] || item[:percentage]
        next if raw_key.blank? || percentage.nil?

        result[raw_key] = percentage
      end
    end

    enrichments = {}
    api_error_count = 0
    skipped_count = 0

    grouped_rows.each do |social_account_id, account_rows|
      sorted_rows = account_rows.sort_by do |(row, _idx)|
        Date.parse(row["date"])
      rescue StandardError
        Date.new(9999, 12, 31)
      end

      account = SocialAccount.find_by(id: social_account_id)
      token = account&.raw_channel_token
      first_month_failed = false

      sorted_rows.each_with_index do |(row, idx), row_index|
        if first_month_failed
          enrichments[idx] = {
            "gender_ratios" => "APIエラー",
            "age_ratios" => "APIエラー",
            "area_ratios" => "APIエラー",
            "demographic_api_status" => "APIエラー",
            "demographic_error" => "first_month_api_error_skip"
          }
          skipped_count += 1
          next
        end

        begin
          raise LineInsightClient::Error, "missing_social_account" if account.nil?
          raise LineInsightClient::Error, "missing_token" if token.blank?

          date = Date.parse(row["date"])
          attempt = 0
          begin
            attempt += 1
            body = LineInsightClient.get_demographic(channel_token: token, date: date.strftime("%Y%m%d"))
          rescue LineInsightClient::Error => e
            # LINE demographic API may return temporary 429; retry before failing the month.
            if e.message.include?("HTTP 429") && attempt < 5
              sleep(0.5 * (2**(attempt - 1)))
              retry
            end
            raise
          end
          # demographic API returns "available" instead of follower API's "status".
          available = body["available"]
          status = body["status"] || (available == true ? "available" : "unavailable")

          genders = ratio_hash.call(body["genders"] || body["gender"], "gender")
          ages = ratio_hash.call(body["ages"] || body["age"], "age")
          areas = ratio_hash.call(body["areas"] || body["area"], "area")

          enrichments[idx] = {
            "gender_ratios" => (available == true ? genders.to_json : nil),
            "age_ratios" => (available == true ? ages.to_json : nil),
            "area_ratios" => (available == true ? areas.to_json : nil),
            "demographic_api_status" => status,
            "demographic_error" => nil
          }
        rescue LineInsightClient::Error, StandardError => e
          enrichments[idx] = {
            "gender_ratios" => "APIエラー",
            "age_ratios" => "APIエラー",
            "area_ratios" => "APIエラー",
            "demographic_api_status" => "APIエラー",
            "demographic_error" => e.message
          }
          api_error_count += 1
          first_month_failed = true if row_index.zero?
        ensure
          sleep(sleep_sec) if sleep_sec.positive?
        end
      end
    end

    additional_headers = %w[
      gender_ratios
      age_ratios
      area_ratios
      demographic_api_status
      demographic_error
    ]
    headers = rows.headers + additional_headers.reject { |h| rows.headers.include?(h) }

    CSV.open(output_path, "w", write_headers: true, headers: headers) do |csv|
      rows_with_index.each do |row, idx|
        enrichment = enrichments[idx] || {}
        csv << headers.map { |header| row[header] || enrichment[header] }
      end
    end

    puts "Wrote #{rows.size} rows to #{output_path}"
    puts "Demographic API errors: #{api_error_count}"
    puts "Rows skipped due to first-month API error: #{skipped_count}"
  end
end
