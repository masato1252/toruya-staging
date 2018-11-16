class WarningsController < ApplicationController
  include Authorization
  include ViewHelpers
  layout false
  before_action :set_warning_shop, only: [:shop_dashboard_for_staff]

  def shop_dashboard_for_staff; end

  private

  def set_warning_shop
    @warning_shop ||= Shop.find(params[:warning_shop_id])
  end
end
