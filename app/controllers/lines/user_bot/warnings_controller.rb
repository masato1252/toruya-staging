class Lines::UserBot::WarningsController < ActionController::Base
  include UserBotAuthorization
  include ViewHelpers
  include UserBotCookies
  layout false

  def create_booking_page
    flash[:redirect_to] = request.referrer

    render template: "warnings/create_booking_page"
  end

  def create_reservation
    @owner = User.find(params[:owner_id])
    @shop = Shop.find_by(id: params[:shop_id])

    user_ability = ability(@owner, @shop)

    view = if user_ability.cannot?(:create, :reservation_with_settings)
             "empty_reservation_setting_user_modal"
           elsif @shop && user_ability.cannot?(:create_shop_reservations_with_menu, @shop)
             "empty_menu_shop_modal"
           elsif user_ability.cannot?(:create, :daily_reservations)
             @owner == current_user ? "admin_upgrade_daily_reservations_limit_modal" : "staff_upgrade_daily_reservations_limit_modal"
           elsif user_ability.cannot?(:create, :total_reservations)
             @owner == current_user ? "admin_upgrade_total_reservations_limit_modal" : "staff_upgrade_total_reservations_limit_modal"
           else
             Rollbar.warning('Unexpected input', request: request, parameters: params)
             "default_creation_reservation_warning"
           end

    flash[:redirect_to] = request.referrer
    render template: "warnings/#{view}"
  end

  private

  def from_line_bot
    true
  end
  helper_method :from_line_bot
end
