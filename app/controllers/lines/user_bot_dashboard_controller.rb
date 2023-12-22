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
    if !@current_user && params[:encrypted_user_id]
      @current_user = User.find_by(id: MessageEncryptor.decrypt(params[:encrypted_user_id]))
      write_user_bot_cookies(:current_user_id, @current_user.id) if @current_user
    end

    @current_user
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

  def device_detector
    @device_detector ||=
      begin
        Current.device_detector = DeviceDetector.new(request.user_agent)
      end
  end
  helper_method :device_detector

  def business_owner_id
    params[:business_owner_id].presence || Current.business_owner&.id
  end
  helper_method :business_owner_id

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
end
