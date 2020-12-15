class LiffRouting
  USER_BOT_LIFF_ENDPOINT = "https://liff.line.me/#{Rails.application.secrets.toruya_liff_id}".freeze

  class << self
    # mapping to # https://toruya.com/lines/liff/{path}
    def liff_url(path)
      if @@liff_routing.keys.exclude?(path)
        raise "Unexpect path"
      end

      "#{USER_BOT_LIFF_ENDPOINT}/#{path}"
    end

    def url(liff_path)
      formatted_path = liff_path[0] == "/" ? liff_path[1..-1] : liff_path

      @@liff_routing[formatted_path.to_sym]
    end

    def map(liff_path, url)
      @@liff_routing ||= {}
      @@liff_routing[liff_path] = Rails.application.routes.url_helpers.public_send(url)
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
  map :new_booking_setting, :new_lines_user_bot_booking_url
  map :notifications, :lines_user_bot_notifications_url
end
