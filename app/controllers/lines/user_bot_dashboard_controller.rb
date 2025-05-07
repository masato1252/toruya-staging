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
  include UserBotExceptionHandler
  include ControllerHelpers

  skip_before_action :track_ahoy_visit
  before_action :set_locale
  before_action :redirect_from_rich_menu

  def from_line_bot
    true
  end
  helper_method :from_line_bot

  def site_routing_helper
    @site_routing_helper ||= SiteRouting.new(view_context)
  end
  helper_method :site_routing_helper

  def device_detector
    @device_detector ||=
      begin
        Current.device_detector = DeviceDetector.new(request.user_agent)
      end
  end
  helper_method :device_detector

  def shop_menus_options
    @shop_menus_options ||=
      ShopMenu.includes(:menu).where(shop: shop).where("menus.deleted_at": nil).references(:menus).map do |shop_menu|
        ::Options::MenuOption.new(
          id: shop_menu.menu_id,
          name: shop_menu.menu.display_name,
          min_staffs_number: shop_menu.menu.min_staffs_number,
          available_seat: shop_menu.max_seat_number,
          minutes: shop_menu.menu.minutes,
          interval: shop_menu.menu.interval,
          online: shop_menu.menu.online
        )
      end
  end

  def redirect_from_rich_menu
    if params[:redirect_from_rich_menu] && current_social_user && current_social_user.manage_accounts.size > 1
      @redirect_controller = controller_name
      @redirect_action = action_name
      render template: "lines/user_bot/business_owners"
      return
    end
  end

  def set_locale
    I18n.locale = params[:locale].presence || Current.business_owner&.locale || cookies[:locale] || I18n.default_locale
    cookies[:locale] = {
      value: I18n.locale,
      domain: :all,
      expires: 20.years.from_now
    }
    Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
  end

  def notify_user_customer_reservation_confirmation_message
    if Current.notify_user_customer_reservation_confirmation_message
      Current.notify_user_customer_reservation_confirmation_message = false
      flash[:notice] = I18n.t("common.notify_user_customer_reservation_confirmation_message")
    end
  end
end