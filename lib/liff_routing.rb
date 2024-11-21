# frozen_string_literal: true

class LiffRouting
  LIFF_BASE_URL = "https://liff.line.me".freeze
  
  class << self
    def liff_url(path, locale = 'ja')
      if @@liff_routing.keys.exclude?(path)
        raise "Unexpect path"
      end

      "#{liff_endpoint(locale)}/#{path}"
    end

    def url(liff_path, locale = 'ja')
      formatted_path = liff_path[0] == "/" ? liff_path[1..-1] : liff_path
      @@liff_routing[formatted_path.to_sym]
    end

    def map(liff_path, url)
      @@liff_routing ||= {}
      @@liff_routing[liff_path] = Rails.application.routes.url_helpers.public_send(url) unless Rails.env.test?
    end

    private

    def liff_endpoint(locale)
      liff_id = Rails.application.secrets[locale][:toruya_liff_id]
      "#{LIFF_BASE_URL}/#{liff_id}"
    end
  end

  # map :liff_path, :toruya_url
  # liff_path is the path behind https://liff.line.me/#{LIFF_ID}/liff_path
  # toruya_url is the url users be redirected
  # The redirect behavior happens in Lines::LiffController
  # the liff_path value might be in params[:liff_path] or params["liff.state"]
  map :users_connect, :lines_user_bot_connect_user_url
  map :users_sign_up, :lines_user_bot_sign_up_url
  map :schedules, :lines_user_bot_schedules_url
  map :customers, :lines_user_bot_customers_url
  map :settings, :lines_user_bot_settings_url
  map :booking_pages, :lines_user_bot_booking_pages_url
  map :booking_options, :lines_user_bot_booking_options_url
  map :menus, :lines_user_bot_settings_menus_path
  map :new_booking_setting, :new_lines_user_bot_booking_url
  map :new_broadcast, :new_lines_user_bot_broadcast_url
  map :broadcasts, :lines_user_bot_broadcasts_url
  map :new_sales, :new_lines_user_bot_sale_url
  map :sales, :lines_user_bot_sales_url
  map :new_online_service, :new_lines_user_bot_service_url
  map :online_services, :lines_user_bot_services_url
  map :notifications, :lines_user_bot_notifications_url
end
