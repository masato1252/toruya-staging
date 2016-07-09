class DashboardController < ActionController::Base
  layout "dashboard"
  protect_from_forgery with: :exception, prepend: true

  before_action :authenticate_user!

  def shops
    @shops ||= current_user.shops
  end
  helper_method :shops

  # Use callbacks to share common setup or constraints between actions.
  def shop
    @shop ||= current_user.shops.find_by(id: params[:shop_id])
  end
  helper_method :shop
end
