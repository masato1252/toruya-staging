# frozen_string_literal: true

class Lines::UserBot::WarningsController < Lines::UserBotDashboardController
  layout false

  def create_course
    write_user_bot_cookies(:redirect_to, request.referrer)

    render template: "warnings/create_course"
  end

  def check_reservation_content
    write_user_bot_cookies(:redirect_to, request.referrer)

    if Current.business_owner.trial_member?
      render template: "warnings/check_reservation_content"
    else
      # free member
      render template: "warnings/trial_end"
    end
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
             # Rollbar.warning('Unexpected input', request: request, parameters: params)
             "default_creation_reservation_warning"
           end

    write_user_bot_cookies(:redirect_to, request.referrer)
    render template: "warnings/#{view}"
  end

  def cancel_paid_customers
    @reservation = Reservation.find(params[:reservation_id])
    @paid_reservation_customers = @reservation.reservation_customers.payment_paid.includes(:customer)

    render template: "warnings/cancel_paid_customers"
  end

  def line_settings_verified
    write_user_bot_cookies(:redirect_to, request.referrer)

    render template: "warnings/line_settings_verified"
  end

  def trial_end
    write_user_bot_cookies(:redirect_to, request.referrer)

    render template: "warnings/trial_end"
  end

  def change_verified_line_settings
    write_user_bot_cookies(:redirect_to, request.referrer)

    render template: "warnings/change_verified_line_settings"
  end

  private

  def from_line_bot
    true
  end
  helper_method :from_line_bot
end
