class WarningsController < ApplicationController
  include Authorization
  include ViewHelpers
  layout false
  before_action :set_warning_shop, only: [:shop_dashboard_for_staff, :shop_dashboard_for_admin]

  def shop_dashboard_for_staff; end

  def shop_dashboard_for_admin; end

  def edit_staff_for_admin; end

  def new_staff_for_admin; end

  private

  def set_warning_shop
    @warning_shop ||= Shop.find(params[:warning_shop_id])
  end
end
