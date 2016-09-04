class DashboardController < ActionController::Base
  layout "application"
  protect_from_forgery with: :exception, prepend: true

  before_action :authenticate_user!

 rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound do
   redirect_to root_path, :alert => "This page does not exist."
 end

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
