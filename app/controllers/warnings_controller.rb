# frozen_string_literal: true

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

  def admin_upgrade_filter_modal;end

  def create_booking_page;end

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

    render view
  end

  private

  def from_line_bot
    false
  end
  helper_method :from_line_bot

  def set_warning_shop
    @warning_shop ||= Shop.find(params[:warning_shop_id])
  end
end
