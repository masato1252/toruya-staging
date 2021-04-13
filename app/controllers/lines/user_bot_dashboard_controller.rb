# frozen_string_literal: true

require "user_bot_cookies"
require "liff_routing"
require "site_routing"

class Lines::UserBotDashboardController < ActionController::Base
  abstract!

  layout "user_bot"

  include UserBotCookies
  include UserBotAuthorization
  include ViewHelpers
  include ParameterConverters
  include Locale
  include UserBotExceptionHandler
  include ControllerHelpers

  skip_before_action :track_ahoy_visit

  def current_user
    @current_user ||= User.find_by(id: ENV["DEV_USER_ID"] || user_bot_cookies(:current_user_id))
  end
  helper_method :current_user

  def social_user
    @social_user ||= SocialUser.find_by!(social_service_user_id: user_bot_cookies(:social_service_user_id))
  end
  helper_method :social_user

  def from_line_bot
    true
  end
  helper_method :from_line_bot

  def site_routing_helper
    @site_routing_helper ||= SiteRouting.new(view_context)
  end
  helper_method :site_routing_helper

  def shop_menus_options
    @shop_menus_options ||=
      ShopMenu.includes(:menu).where(shop: shop).map do |shop_menu|
        ::Options::MenuOption.new(
          id: shop_menu.menu_id,
          name: shop_menu.menu.display_name,
          min_staffs_number: shop_menu.menu.min_staffs_number,
          available_seat: shop_menu.max_seat_number,
          minutes: shop_menu.menu.minutes,
          interval: shop_menu.menu.interval
        )
      end
  end
end
