class SettingsController < ActionController::Base
  layout "settings"
  before_action :authenticate_user!

  include AccountRequirement

  def shops
    @shops ||= current_user.shops
  end
  helper_method :shops

  # Use callbacks to share common setup or constraints between actions.
  def shop
    @shop ||= current_user.shops.find_by(id: params[:shop_id])
  end
  helper_method :shop

  def super_user
    current_user
  end
  helper_method :super_user
end
