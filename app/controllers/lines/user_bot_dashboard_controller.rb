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
  before_action :save_business_owner_preference
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
      # Check if user has a saved business owner preference
      saved_business_owner_id = user_bot_cookies(:preferred_business_owner_id)

      if saved_business_owner_id.present?
        # Verify the saved business owner is still valid for this user
        if valid_business_owner_id?(saved_business_owner_id)
          # Auto-redirect to saved business owner
          redirect_to url_for(controller: controller_name, action: action_name, business_owner_id: saved_business_owner_id, **request.query_parameters.except(:redirect_from_rich_menu))
          return
        else
          # Clear invalid saved preference
          delete_user_bot_cookies(:preferred_business_owner_id)
        end
      end

      # Show business owner selection page
      @redirect_controller = controller_name
      @redirect_action = action_name
      render template: "lines/user_bot/business_owners"
      return
    end
  end

  def set_locale
    I18n.locale = params[:locale].presence || Current.business_owner&.locale || cookies[:locale] || I18n.default_locale
    cookies.clear_across_domains(:locale)
    cookies.set_across_domains(:locale, I18n.locale, expires: 20.years.from_now)
    Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
  end

  def notify_user_customer_reservation_confirmation_message
    if Current.notify_user_customer_reservation_confirmation_message
      Current.notify_user_customer_reservation_confirmation_message = false
      flash[:notice] = I18n.t("common.notify_user_customer_reservation_confirmation_message")
    end
  end

  private

    def save_business_owner_preference
    return unless params[:business_owner_id].present? && current_social_user

    current_business_owner_id = params[:business_owner_id]
    saved_business_owner_id = user_bot_cookies(:preferred_business_owner_id)

    # Only save if the business_owner_id has changed and is valid
    if current_business_owner_id != saved_business_owner_id &&
       valid_business_owner_id?(current_business_owner_id)
      write_user_bot_cookies(:preferred_business_owner_id, current_business_owner_id)
    end
  end

  def valid_business_owner_id?(business_owner_id)
    @valid_business_owner_ids ||= current_social_user.manage_accounts.pluck(:id).map(&:to_s)
    @valid_business_owner_ids.include?(business_owner_id.to_s)
  end

  def clear_business_owner_preference
    delete_user_bot_cookies(:preferred_business_owner_id)
  end
  helper_method :clear_business_owner_preference
end