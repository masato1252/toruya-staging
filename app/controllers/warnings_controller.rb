class WarningsController < ApplicationController
  include Authorization
  include ViewHelpers
  layout false
  before_action :set_warning_shop, only: [:shop_dashboard_for_staff, :shop_dashboard_for_admin, :read_settings_dashboard_for_staff]

  def shop_dashboard_for_staff; end

  def shop_dashboard_for_admin; end

  def customer_dashboard_for_staff
    @owner = User.find(params[:owner_id])
  end

  def filter_dashboard_for_staff
    @owner = User.find(params[:owner_id])
  end

  def read_settings_dashboard_for_staff; end

  def edit_staff_for_admin; end

  def new_staff_for_admin; end

  def create_reservation
    @owner = User.find(params[:owner_id])
    @shop = Shop.find_by(id: params[:shop_id])

    user_ability = ability(@owner)

    view = if user_ability.cannot?(:create, :reservation_with_settings)
             "empty_reservation_setting_user_modal"
           elsif user_ability.cannot?(:create_shop_reservations_with_menu, @shop)
             "empty_menu_shop_modal"
           elsif user_ability.cannot?(:create, :daily_reservations)
             @owner == current_user ? "admin_upgrade_daily_reservations_limit_modal" : "staff_upgrade_daily_reservations_limit_modal"
           elsif user_ability.cannot?(:create, :total_reservations)
             @owner == current_user ? "admin_upgrade_total_reservations_limit_modal" : "staff_upgrade_total_reservations_limit_modal"
           end

    render view
  end

  private

  def set_warning_shop
    @warning_shop ||= Shop.find(params[:warning_shop_id])
  end
end
