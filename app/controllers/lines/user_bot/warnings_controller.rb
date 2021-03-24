# frozen_string_literal: true

class Lines::UserBot::WarningsController < Lines::UserBotDashboardController
  layout false

  def create_booking_page
    write_user_bot_cookies(:redirect_to, request.referrer)

    render template: "warnings/create_booking_page"
  end

  def check_reservation_content
    write_user_bot_cookies(:redirect_to, request.referrer)

    render template: "warnings/check_reservation_content"
  end

  def create_reservation
    @owner = User.find(params[:owner_id])
    @shop = Shop.find_by(id: params[:shop_id])

    user_ability = ability(@owner, @shop)

    view = if user_ability.cannot?(:create, :reservation_with_settings)
             "empty_reservation_setting_user_modal"
           elsif @shop && user_ability.cannot?(:create_shop_reservations_with_menu, @shop)
             "empty_menu_shop_modal"
           else
             Rollbar.warning('Unexpected input', request: request, parameters: params)
             "default_creation_reservation_warning"
           end

    write_user_bot_cookies(:redirect_to, request.referrer)
    render template: "warnings/#{view}"
  end

  private

  def from_line_bot
    true
  end
  helper_method :from_line_bot
end
